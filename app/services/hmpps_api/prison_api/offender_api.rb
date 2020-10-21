# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class OffenderApi
      extend PrisonApiClient

      def self.list(prison, page = 0, page_size: 20)
        route = "/locations/description/#{prison}/inmates"

        queryparams = { 'convictedStatus' => 'Convicted', 'returnCategory' => true }

        page_offset = page * page_size
        hdrs = paging_headers(page_size, page_offset)

        key = "offender_list_page_#{prison}_#{page}_#{page_size}"

        data, total_pages = Rails.cache.fetch(
          key,
          expires_in: Rails.configuration.cache_expiry) {
          total_pages = nil

          data = client.get(
            route, queryparams: queryparams, extra_headers: hdrs
          ) { |_json, response|
            total_records = response.headers['Total-Records'].to_i
            total_pages = (total_records / page_size.to_f).ceil
          }

          [data, total_pages]
        }

        recall_data = get_recall_flags(data.map { |o| o.fetch('offenderNo') })
        data.each do |offender|
          offender.merge!(recall_data.fetch(offender.fetch('offenderNo')))
        end

        offenders = api_deserialiser.deserialise_many(HmppsApi::OffenderSummary, data)
        ApiPaginatedResponse.new(total_pages, offenders)
      end

      def self.get_offender(offender_no)
        get_offenders([offender_no]).first
      end

      def self.get_offenders(offender_no_list)
        api_deserialiser.deserialise_many(HmppsApi::Prisoner, get_prisoners(offender_no_list)).tap do |list|
          booking_ids = list.map(&:booking_id)
          sentence_details = HmppsApi::PrisonApi::OffenderApi.get_bulk_sentence_details(booking_ids)

          list.each do |offender|
            offender.sentence = sentence_details[offender.booking_id]
          end

          add_arrival_dates(list)
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
        data = client.post(route, [offender_no])
        return '' if data.empty?

        data.first['classificationCode']
      end

      def self.get_bulk_sentence_details(booking_ids)
        return {} if booking_ids.empty?

        route = '/offender-sentences/bookings'

        h = Digest::SHA256.hexdigest(booking_ids.to_s)
        key = "bulk_sentence_#{h}"

        data = Rails.cache.fetch(key, expires_in: Rails.configuration.cache_expiry) {
          client.post(route, booking_ids)
        }

        data.each_with_object({}) { |record, hash|
          next unless record.key?('bookingId')

          oid = record['bookingId']

          hash[oid] = api_deserialiser.deserialise(
            HmppsApi::SentenceDetail, record['sentenceDetail']
          )
          hash
        }
      end

      def self.get_image(booking_id)
        # This method returns the raw bytes of an image, the equivalent of loading the
        # image from file on disk.
        details_route = '/offender-sentences/bookings'
        details = client.post(details_route, [booking_id])

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
          offender.prison_arrival_date = [offender.sentence_start_date, arrival&.create_date_time].compact.max
        end
      end

    private

      def self.get_recall_flags(offender_nos)
        search_result = get_prisoners(offender_nos).index_by { |prisoner| prisoner.fetch('prisonerNumber') }
        offender_nos.index_with { |nomis_id| { 'recall' => search_result.fetch(nomis_id, {}).fetch('recall', false) } }
      end

      def self.get_prisoners(offender_nos)
        search_route = '/prisoner-numbers'
        search_key = "#{search_route}_#{Digest::SHA256.hexdigest(offender_nos.to_s)}"
        Rails.cache.fetch(search_key,
                          expires_in: Rails.configuration.cache_expiry) {
          search_client.post(search_route, prisonerNumbers: offender_nos)
        }
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
