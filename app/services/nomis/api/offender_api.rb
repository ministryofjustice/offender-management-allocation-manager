module Nomis
  module Api
    class OffenderApi
      extend Elite2Api

      # rubocop:disable Metrics/MethodLength
      def self.list(prison, page = 0, page_size: 10)
        route = "/elite2api/api/locations/description/#{prison}/inmates"

        page_meta = nil
        page_offset = page * page_size
        hdrs = paging_headers(page_size, page_offset)

        data = e2_client.get(route, extra_headers: hdrs) { |json, response|
          total_records = response.headers['Total-Records'].to_i
          records_shown = json.length
          page_meta = make_page_meta(
            page, page_size, total_records, records_shown
          )
        }

        offenders = data.map { |offender|
          api_deserialiser.deserialise(Nomis::Models::OffenderShort, offender)
        }

        ApiPaginatedResponse.new(page_meta, offenders)
      end

      def self.get(offender_no)
        route = "/elite2api/api/prisoners/#{offender_no}"
        response = e2_client.get(route) { |data|
          raise Nomis::Client::APIError, 'No data was returned' if data.empty?
        }

        api_deserialiser.deserialise(Nomis::Models::Offender, response.first)
      rescue Nomis::Client::APIError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        Nomis::Models::NullOffender.new
      end
      # rubocop:enable Metrics/MethodLength

      def self.get_offence(booking_id)
        route = "/elite2api/api/bookings/#{booking_id}/mainOffence"
        data = e2_client.get(route)
        data.first['offenceDescription']
      end

      def self.get_bulk_sentence_details(offender_ids)
        return {} if offender_ids.empty?

        route = '/elite2api/api/offender-sentences'

        data = e2_client.post(route, offender_ids)

        data.each_with_object({}) { |record, hash|
          oid = record['offenderNo']
          hash[oid] = api_deserialiser.deserialise(Nomis::Models::SentenceDetail, record)
        }
      end

    private

      def self.paging_headers(page_size, page_offset)
        {
          'Page-Limit' => page_size.to_s,
          'Page-Offset' => page_offset.to_s
        }
      end

      def self.make_page_meta(current_page, size, total, records_shown)
        PageMeta.new.tap{ |p|
          p.size = size
          p.total_elements = total
          p.total_pages = (total / size.to_f).ceil
          p.number = current_page
          p.items_on_page = records_shown
        }
      end
    end
  end
end
