# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class OffenderApi
      extend PrisonApiClient

      # Only allow offenders into the service if their legal status is in this list
      # Used to filter out offenders who are on remand, civil prisoners, unsentenced, etc.
      ALLOWED_LEGAL_STATUSES = %w[SENTENCED INDETERMINATE_SENTENCE RECALL IMMIGRATION_DETAINEE].freeze

      def self.get_offenders_in_prison(prison)
        # Get offenders from the Prisoner Offender Search API - and filter out those with unwanted legal statuses
        offenders = get_search_api_offenders_in_prison(prison).select { |o|
          ALLOWED_LEGAL_STATUSES.include?(o['legalStatus']) || o['restrictedPatient'] == true
        }

        return [] if offenders.empty?

        # Get additional data from other APIs
        offender_nos = offenders.map { |o| o.fetch('prisonerNumber') }
        offender_categories = get_offender_categories(offender_nos)
        complexities = if Prison.womens.exists?(prison)
                         HmppsApi::ComplexityApi.get_complexities(offender_nos)
                       else
                         {}
                       end

        # Get movement details only for those offenders who are temporarily out of prison (TAP/ROTL)
        temp_out_offenders = offenders.select { |o| temp_out_of_prison?(o) }.map { |o| o.fetch('prisonerNumber') }
        temp_movements = if temp_out_offenders.any?
                           HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for(temp_out_offenders)
                         else
                           {}
                         end

        # Create Offender objects
        offenders.map { |offender|
          offender_no = offender.fetch('prisonerNumber')

          HmppsApi::Offender.new(
            offender: offender,
            category: offender_categories[offender_no],
            latest_temp_movement: temp_movements[offender_no],
            complexity_level: complexities[offender_no]
          )
        }.tap do |offenders_array|
          add_arrival_dates(offenders_array)
        end
      end

      # Get a single offender
      #
      # Returns nil if the offender's legal status is not in the list ALLOWED_LEGAL_STATUSES
      # To ignore the ALLOWED_LEGAL_STATUSES list and return the offender anyway, set `ignore_legal_status` to true.
      # Warning: when you ignore the offender's legal status, you could potentially receive an offender who wouldn't
      # normally appear within the service. This should only be done under certain circumstances –
      # e.g. when deallocating an offender who has since left the service due to a change in legal status
      def self.get_offender(raw_offender_no, ignore_legal_status: false)
        # Get offender from the Prisoner Offender Search API
        offender = get_search_api_offenders([raw_offender_no]).first
        # ignore legal status if override flag is present, or offender is a Restricted Patient
        # MPC should always show Restricted Patients, since they must have been sentenced before being sent to
        # a hospital
        return nil unless offender.present? && (
            ALLOWED_LEGAL_STATUSES.include?(offender['legalStatus']) ||
            (ignore_legal_status || offender['restrictedPatient'] == true)
        )

        offender_no = offender.fetch('prisonerNumber')

        # Restricted Patients use supportingPrisonId, since the offender is currently in hospital
        prison_id = offender.fetch('restrictedPatient') == true ? offender.fetch('supportingPrisonId') : offender.fetch('prisonId')
        complexity_level = if Prison.womens.exists?(prison_id)
                             HmppsApi::ComplexityApi.get_complexity(offender_no)
                           end

        # Get additional data from other APIs
        offender_categories = get_offender_categories([offender_no])
        temp_movement = if temp_out_of_prison?(offender)
                          HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for([offender_no])[offender_no]
                        end

        HmppsApi::Offender.new(
          offender: offender,
          category: offender_categories[offender_no],
          latest_temp_movement: temp_movement,
          complexity_level: complexity_level
        ).tap do |o|
          add_arrival_dates([o])
        end
      end

      def self.get_offender_categories(offender_nos)
        # This route is CASE SENSITIVE
        # We call the Prison API endpoint /api/offender-assessments/{assessmentCode} with "CATEGORY"
        # We **DO NOT** call the endpoint /api/offender-assessments/category
        # These endpoints do different things and we want to use the first one,
        # hence the use of uppercase "CATEGORY" here.
        route = '/offender-assessments/CATEGORY'

        # I think these might actually be the default options on this endpoint, but it's better to be explicit & safe
        # latestOnly and mostRecentlyOnly are subtly different – we need both to be true
        # activeOnly ensures we don't see any category assessments which haven't yet been approved
        queryparams = { 'latestOnly' => true, 'activeOnly' => true, 'mostRecentOnly' => true }

        client.post(route, offender_nos, queryparams: queryparams, cache: true)
              .map { |assessment|
                [assessment.fetch('offenderNo'), HmppsApi::OffenderCategory.new(assessment)]
              }.to_h
      end

      def self.get_image(booking_id)
        # This method returns the raw bytes of an image, the equivalent of loading the
        # image from file on disk.
        details_route = '/offender-sentences/bookings'
        details = client.post(details_route, [booking_id], cache: true)

        return default_image if details.first['facialImageId'].blank?

        image_route = "/images/#{details.first['facialImageId']}/data"
        image = client.raw_get(image_route)

        image.presence || default_image
      rescue Faraday::ResourceNotFound
        # It's possible that the offender does not yet have an image of their
        # face, and so when an image can't be found, we will return the default
        # image instead.
        default_image
      end

      def self.add_arrival_dates(offenders)
        movements = HmppsApi::PrisonApi::MovementApi.admissions_for(offenders.map(&:offender_no))

        offenders.each do |offender|
          arrival = movements.fetch(offender.offender_no, []).reverse.detect { |movement|
            movement.to_agency == offender.prison_id
          }
          offender.prison_arrival_date = [offender.sentence_start_date, arrival&.movement_date].compact.max
        end
      end

    private

      def self.get_search_api_offenders_in_prison(prison_code)
        route = "/prisoner-search/prison/#{prison_code}"

        # Pagination was found to be faulty on this API endpoint (see Jira ticket DT-2719)
        # So here we bypass pagination by asking for 10,000 results per page.
        # There are only ever up to ~2000 offenders per prison, and this API seems happy to return them all at once.
        # This endpoint also requires a "Content-Type: application/json" header even though it's a GET request with no body.
        search_client.get(route, queryparams: { page: 0, size: 10_000, 'include-restricted-patients': true }, extra_headers: { 'Content-Type': 'application/json' })
                     .fetch('content')
      end

      def self.get_search_api_offenders(offender_nos)
        search_route = '/prisoner-search/prisoner-numbers'
        search_client.post(search_route, { prisonerNumbers: offender_nos }, queryparams: { 'include-restricted-patients': true }, cache: true)
      end

      def self.default_image
        File.read(Rails.root.join('app/assets/images/default_profile_image.jpg'))
      end

      def self.temp_out_of_prison?(offender)
        offender['inOutStatus'] == 'OUT' && offender['lastMovementTypeCode'] == HmppsApi::MovementType::TEMPORARY
      end
    end
  end
end
