module Nomis
  module Elite2
    ApiResponse = Struct.new(:data)
    ApiPaginatedResponse = Struct.new(:meta, :data)

    class Api
      include Singleton

      class << self
        delegate :get_offender_list, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @e2_client = Nomis::Client.new(host)
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
          api_deserialiser.deserialise(Nomis::OffenderShort, offender)
        }

        # We have to add the empty item to the list because otherwise we only get the
        # last item. This appears to be a bug in faraday because the Elite2 API works
        # fine with the same URL when called via Postman.
        ids = offenders.map(&:offender_no) + ['']
        release_dates = get_bulk_release_dates(ids)

        offenders.each do |offender|
          offender.release_date = release_dates[offender.offender_no]
        end

        ApiPaginatedResponse.new(page_meta, offenders)
      end
    # rubocop:enable Metrics/MethodLength

    private

      def get_bulk_release_dates(prisoner_ids)
        route = '/elite2api/api/offender-sentences'
        parameters = { 'offenderNo' => prisoner_ids }
        data = @e2_client.get(route, queryparams: parameters)

        data.each_with_object({}) { |record, hsh|
          offender_no = record['offenderNo']
          release_date = record['sentenceDetail'].fetch('releaseDate', '')
          hsh[offender_no] = release_date
        }
      end

      def paging_headers(page_size, page_offset)
        {
          'Page-Size' => page_size.to_s,
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
