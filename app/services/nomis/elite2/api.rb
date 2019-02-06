module Nomis
  module Elite2
    ApiResponse = Struct.new(:data)
    ApiPaginatedResponse = Struct.new(:meta, :data)

    class Api
      include Singleton

      class << self
        delegate :get_offender, to: :instance
        delegate :get_offender_list, to: :instance
        delegate :get_bulk_release_dates, to: :instance
        delegate :get_offence, to: :instance
        delegate :get_offender, to: :instance
        delegate :fetch_nomis_user_details, to: :instance
        delegate :prisoner_offender_manager_list, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @e2_client = Nomis::Client.new(host)
      end

      def fetch_nomis_user_details(username)
        route = "/elite2api/api/users/#{username}"
        response = @e2_client.get(route)

        ApiResponse.new(api_deserialiser.
          deserialise(Nomis::Elite2::UserDetails, response))
      end

      def prisoner_offender_manager_list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        response = @e2_client.get(route) { |data|
          raise Nomis::Client::APIError, 'No data was returned' if data.empty?
        }

        poms = response.map { |pom|
          api_deserialiser.deserialise(Nomis::Elite2::PrisonOffenderManager, pom)
        }

        ApiResponse.new(poms)
      end

      # rubocop:disable Metrics/MethodLength
      def get_offender_list(prison, page = 0)
        route = "/elite2api/api/locations/description/#{prison}/inmates"

        page_size = 10
        page_offset = page * page_size
        page_meta = nil

        hdrs = paging_headers(page_size, page_offset)

        data = @e2_client.get(route, extra_headers: hdrs) { |json, response|
          total_records = response.headers['Total-Records'].to_i
          records_shown = json.length
          page_meta = make_page_meta(
            page, page_size, total_records, records_shown
          )
        }

        offenders = data.map { |offender|
          api_deserialiser.deserialise(Nomis::Elite2::OffenderShort, offender)
        }

        ApiPaginatedResponse.new(page_meta, offenders)
      end

      def get_offender(offender_no)
        route = "/elite2api/api/prisoners/#{offender_no}"
        response = @e2_client.get(route) { |data|
          raise Nomis::Client::APIError, 'No data was returned' if data.empty?
        }

        ApiResponse.new(
          api_deserialiser.deserialise(Nomis::Elite2::Offender, response.first)
        )
      rescue Nomis::Client::APIError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        ApiResponse.new(NullOffender.new)
      end
      # rubocop:enable Metrics/MethodLength

      def get_offence(booking_id)
        route = "/elite2api/api/bookings/#{booking_id}/mainOffence"
        data = @e2_client.get(route)
        ApiResponse.new(data.first['offenceDescription'])
      end

      def get_bulk_release_dates(offender_ids)
        route = '/elite2api/api/offender-sentences'
        data = @e2_client.post(route, offender_ids)

        results = data.each_with_object({}) { |record, hash|
          oid = record['offenderNo']
          datestring = record['sentenceDetail'].fetch('releaseDate', '')
          hash[oid] = datestring.present? ? Date.parse(datestring) : nil
        }

        ApiResponse.new(results)
      end

    private

      def paging_headers(page_size, page_offset)
        {
          'Page-Limit' => page_size.to_s,
          'Page-Offset' => page_offset.to_s
        }
      end

      def make_page_meta(current_page, size, total, records_shown)
        PageMeta.new.tap{ |p|
          p.size = size
          p.total_elements = total
          p.total_pages = (total / size.to_f).ceil
          p.number = current_page
          p.items_on_page = records_shown
        }
      end

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
