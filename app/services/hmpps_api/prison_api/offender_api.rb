# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class OffenderApi
      extend PrisonApiClient

      def self.list(prison, page = 0, page_size: 20)
        route = "/locations/description/#{prison}/inmates"

        queryparams = { 'convictedStatus' => 'Convicted' }

        page_offset = page * page_size
        hdrs = paging_headers(page_size, page_offset)

        total_pages = nil
        data = client.get(
          route, queryparams: queryparams, extra_headers: hdrs
        ) { |_json, response|
          # Get the 'Total-Records' response header to calculate how many pages there are
          total_records = response.headers['Total-Records'].to_i
          total_pages = (total_records / page_size.to_f).ceil
        }

        offender_nos = data.map { |o| o.fetch('offenderNo') }
        search_data = get_search_payload(offender_nos)
        temp_movements = HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for(offender_nos)
        offender_categories = get_offender_categories(offender_nos)

        booking_ids = data.map { |o| o.fetch('bookingId') }
        sentence_details = HmppsApi::PrisonApi::OffenderApi.get_bulk_sentence_details(booking_ids)

        complexities = if PrisonService::womens_prison?(prison)
                         HmppsApi::ComplexityApi.get_complexities offender_nos
                       else
                         {}
                       end
        # need to ignore any offenders who don't show up in the search API
        offenders = data.select { |p| search_data.key? p.fetch('offenderNo') }.map do |api_payload|
          offender_no = api_payload.fetch('offenderNo')
          search_payload = search_data.fetch(offender_no)
          booking_id = api_payload.fetch('bookingId').to_i
          HmppsApi::Offender.new(api_payload,
                                 search_payload,
                                 booking_id: booking_id,
                                 prison_id: api_payload.fetch('agencyId'),
                                 category: offender_categories[offender_no],
                                 latest_temp_movement: temp_movements[offender_no],
                                 complexity_level: complexities[offender_no]).tap { |offender|
            sentencing = sentence_details[booking_id]
            if sentencing.present?
              offender.sentence = HmppsApi::SentenceDetail.new sentencing,
                                                               search_payload
            end
          }
        end
        ApiPaginatedResponse.new(total_pages, offenders)
      end

      def self.get_offender(raw_offender_no)
        # Bad NOMIS numbers mustn't produce invalid URLs
        offender_no = URI.encode_www_form_component(raw_offender_no)
        route = "/prisoners/#{offender_no}"
        api_payload = client.get(route).first
        search_payload = get_search_payload([offender_no])[offender_no] unless api_payload.nil?

        if api_payload.nil? || search_payload.nil?
          nil
        else
          temp_movements = HmppsApi::PrisonApi::MovementApi.latest_temp_movement_for([offender_no])
          offender_categories = get_offender_categories([offender_no])
          # If the offender is a restricted patient, use the "supporting prison" (because that's where their POM will be)
          prison_id = search_payload['restrictedPatient'] ? search_payload['supportingPrisonId'] : search_payload['prisonId']
          complexity_level = if Prison.womens.exists?(prison_id)
                               HmppsApi::ComplexityApi.get_complexity(offender_no)
                             end
          booking_id = search_payload['bookingId']&.to_i
          prisoner = HmppsApi::Offender.new api_payload,
                                            search_payload,
                                            category: offender_categories[offender_no],
                                            latest_temp_movement: temp_movements[offender_no],
                                            complexity_level: complexity_level,
                                            booking_id: booking_id,
                                            prison_id: prison_id

          prisoner.tap do |offender|
            sentence_details = get_bulk_sentence_details([booking_id])
            sentence = HmppsApi::SentenceDetail.new sentence_details.fetch(booking_id),
                                                    search_payload

            offender.sentence = sentence
            add_arrival_dates([offender])
          end
        end
      end

      def self.get_offence(booking_id)
        route = "/bookings/#{booking_id}/mainOffence"
        data = client.get(route)
        return '' if data.empty?

        data.first['offenceDescription']
      end

      def self.get_category_code(offender_no)
        route = '/offender-assessments/CATEGORY'
        data = client.post(route, [offender_no], cache: true)
        return '' if data.empty?

        data.first['classificationCode']
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

      def self.get_bulk_sentence_details(booking_ids)
        return {} if booking_ids.empty?

        route = '/offender-sentences/bookings'
        data = client.post(route, booking_ids, cache: true)

        data.each_with_object({}) { |record, hash|
          next unless record.key?('bookingId')

          oid = record['bookingId']

          hash[oid] = record.fetch('sentenceDetail')
          hash
        }
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

      def self.get_search_payload(offender_nos)
        search_route = '/prisoner-numbers'
        search_client.post(search_route, { prisonerNumbers: offender_nos }, cache: true)
                                     .index_by { |prisoner| prisoner.fetch('prisonerNumber') }
      end

      def self.paging_headers(page_size, page_offset)
        {
          'Page-Limit' => page_size.to_s,
          'Page-Offset' => page_offset.to_s
        }
      end

      def self.default_image
        File.read(Rails.root.join('app/assets/images/default_profile_image.jpg'))
      end
    end
  end
end
