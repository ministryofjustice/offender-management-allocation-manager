# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class OffenderApi
      extend PrisonApiClient

      # Only allow offenders into the service if their legal status is in this list
      # Used to filter out offenders who are on remand, civil prisoners, unsentenced, etc.
      ALLOWED_LEGAL_STATUSES = %w[SENTENCED INDETERMINATE_SENTENCE RECALL IMMIGRATION_DETAINEE].freeze

      # Despite filtering out civil cases (legal status `CIVIL_PRISONER`) some civil cases
      # will show up as `SENTENCED` legal status, and we need to filter by their sentence type code.
      EXCLUDED_IMPRISONMENT_STATUSES = %w[A_FINE].freeze

      def self.get_offenders_in_prison(prison, *args)
        offenders = get_search_api_offenders_in_prison(prison)

        build_offenders(offenders, prison, *args)
      end

      # Get a single offender
      #
      # Returns nil if the offender's legal status is not in the list ALLOWED_LEGAL_STATUSES
      # To ignore the ALLOWED_LEGAL_STATUSES list and return the offender anyway, set `ignore_legal_status` to true.
      # Warning: when you ignore the offender's legal status, you could potentially receive an offender who wouldn't
      # normally appear within the service. This should only be done under certain circumstances –
      # e.g. when deallocating an offender who has since left the service due to a change in legal status
      def self.get_offender(offender_no, *args)
        offender = get_search_api_offenders(offender_no).first
        return if offender.nil?

        # Restricted Patients use supportingPrisonId, since the offender is currently in hospital
        prison_id = offender.fetch(offender['restrictedPatient'] ? 'supportingPrisonId' : 'prisonId')

        build_offenders([offender], prison_id, *args).first
      end

      def self.build_offenders(unfiltered_offenders, prison_id, *args)
        default_options = {
          ignore_legal_status: false, fetch_complexities: true, fetch_categories: true, fetch_movements: true
        }.freeze

        options = default_options.dup.merge(args.extract_options! || {}).assert_valid_keys(default_options.keys)

        offenders = options[:ignore_legal_status] ? unfiltered_offenders : filtered_offenders(unfiltered_offenders)
        return [] if offenders.empty?

        offender_nos = offenders.pluck('prisonerNumber')

        # Get additional data from other APIs
        offender_categories = options[:fetch_categories] ? get_offender_categories(offender_nos) : {}
        complexities = options[:fetch_complexities] ? complexities_for(offender_nos, prison_id) : {}
        temp_movements = options[:fetch_movements] ? latest_temp_movement_for(offenders) : {}
        movements = options[:fetch_movements] ? HmppsApi::PrisonApi::MovementApi.admissions_for(offender_nos) : {}

        offenders.map do |offender|
          offender_no = offender.fetch('prisonerNumber')

          HmppsApi::Offender.new(
            offender:,
            category: offender_categories[offender_no],
            latest_temp_movement: temp_movements[offender_no],
            complexity_level: complexities[offender_no],
            movements: movements[offender_no]
          )
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

        client
          .post(route, offender_nos, queryparams:, cache: true)
          .map { |assessment| [assessment.fetch('offenderNo'), HmppsApi::OffenderCategory.new(assessment)] }
          .to_h
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

      def self.get_offender_sentences_and_offences(booking_id)
        path = "/offender-sentences/booking/#{booking_id}/sentenceTerms"
        client.get(path)
      end

      def self.filtered_offenders(offenders)
        offenders.select do |o|
          ALLOWED_LEGAL_STATUSES.include?(o['legalStatus']) &&
            EXCLUDED_IMPRISONMENT_STATUSES.exclude?(o['imprisonmentStatus'])
        end
      end

      # Get movement details only for those offenders who are temporarily out of prison (TAP/ROTL)
      def self.latest_temp_movement_for(offenders)
        HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for(
          offenders
            .select { |o| temp_out_of_prison?(o) }
            .map    { |o| o.fetch('prisonerNumber') }
        )
      end

      # Get movement details only for those offenders who are temporarily out of prison (TAP/ROTL)
      def self.temp_out_of_prison?(offender)
        offender['inOutStatus'] == 'OUT' && offender['lastMovementTypeCode'] == HmppsApi::MovementType::TEMPORARY
      end

      # Technically we could use the same API endpoint (POST `/complexity-of-need/multiple/offender-no`)
      # whether it is 1 offender, or many, but to keep the amount of tests that would need to change low, this
      # if-else will maintain backward compatibility (so 1 offender uses GET, more than 1 uses POST).
      #
      def self.complexities_for(offender_nos, prison_id)
        return {} unless Prison.womens.exists?(prison_id)

        if offender_nos.many?
          HmppsApi::ComplexityApi.get_complexities(offender_nos)
        else
          offender_no = offender_nos.first
          { offender_no => HmppsApi::ComplexityApi.get_complexity(offender_no) }
        end
      end

    private

      def self.get_search_api_offenders_in_prison(prison_code)
        route = "/prisoner-search/prison/#{prison_code}"
        page_num = 0
        last_page = false
        results = []

        until last_page
          r = search_client.get(
            route,
            queryparams: { page: page_num, size: 10_000, 'include-restricted-patients': true },
            extra_headers: { 'Content-Type': 'application/json' }
          )
          # last should always indicate the last page of results, do perform manual check just to be safe
          last_page = r.fetch('last') || page_num > r.fetch('totalPages')
          page_num += 1
          results.concat r.fetch('content')
        end

        results
      end

      def self.get_search_api_offenders(offender_nos)
        search_route = '/prisoner-search/prisoner-numbers'
        search_client.post(search_route, { prisonerNumbers: Array(offender_nos) }, queryparams: { 'include-restricted-patients': true }, cache: true)
      end

      def self.default_image
        File.read(Rails.root.join('app/assets/images/default_profile_image.jpg'))
      end
    end
  end
end
