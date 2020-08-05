# frozen_string_literal: true

module Nomis
  module Elite2
    class OffenderApi
      extend Elite2Api

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

          data = e2_client.get(
            route, queryparams: queryparams, extra_headers: hdrs
          ) { |_json, response|
            total_records = response.headers['Total-Records'].to_i
            total_pages = (total_records / page_size.to_f).ceil
          }

          [data, total_pages]
        }

        offenders = api_deserialiser.deserialise_many(
          Nomis::OffenderSummary, data)
        ApiPaginatedResponse.new(total_pages, offenders)
      end

      def self.get_offender(offender_no)
        # Bad NOMIS numbers mustn't produce invalid URLs
        route = "/prisoners/#{URI.encode_www_form_component(offender_no)}"
        response = Rails.cache.fetch("offender-#{route}",
                                     expires_in: Rails.configuration.cache_expiry) {
          e2_client.get(route)
        }

        if response.empty?
          nil
        else
          api_deserialiser.deserialise(Nomis::Offender, response.first)
        end
      end

      def self.get_offence(booking_id)
        route = "/bookings/#{booking_id}/mainOffence"
        data = e2_client.get(route)
        return '' if data.empty?

        data.first['offenceDescription']
      end

      def self.get_category_code(offender_no)
        route = '/offender-assessments/CATEGORY'
        data = e2_client.post(route, [offender_no])
        return '' if data.empty?

        data.first['classificationCode']
      end

      def self.get_bulk_sentence_details(booking_ids)
        return {} if booking_ids.empty?

        route = '/offender-sentences/bookings'

        h = Digest::SHA256.hexdigest(booking_ids.to_s)
        key = "bulk_sentence_#{h}"

        data = Rails.cache.fetch(key, expires_in: Rails.configuration.cache_expiry) {
          e2_client.post(route, booking_ids)
        }

        data.each_with_object({}) { |record, hash|
          next unless record.key?('bookingId')

          oid = record['bookingId']

          hash[oid] = api_deserialiser.deserialise(
            Nomis::SentenceDetail, record['sentenceDetail']
          )
          hash
        }
      end

      def self.get_image(booking_id)
        # This method returns the raw bytes of an image, the equivalent of loading the
        # image from file on disk.
        details_route = '/offender-sentences/bookings'
        details = e2_client.post(details_route, [booking_id])

        return default_image if details.first['facialImageId'].blank?

        image_route = "/images/#{details.first['facialImageId']}/data"
        image = e2_client.raw_get(image_route)

        image.presence || default_image
      rescue Faraday::ResourceNotFound
        # It's possible that the offender does not yet have an image of their
        # face, and so when an image can't be found, we will return the default
        # image instead.
        default_image
      end

    private

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
