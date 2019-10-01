# frozen_string_literal: true

module Nomis
  module Elite2
    class MovementApi
      extend Elite2Api

      def self.movements_on_date(date)
        route = '/elite2api/api/movements'

        data = e2_client.get(route, queryparams: {
                               movementDate: date.strftime('%F'),
                               fromDateTime: (date - 1.day).strftime('%FT%R')
                             })
        data.map { |movement|
          api_deserialiser.deserialise(Nomis::Movement, movement)
        }
      end

      # rubocop:disable Metrics/LineLength
      def self.movements_for(offender_no)
        route = '/elite2api/api/movements/offenders?movementTypes=ADM&movementTypes=TRN&movementTypes=REL&latestOnly=false'

        data = e2_client.post(route, [offender_no])
        data.sort_by { |k| k['createDateTime'] }.map{ |movement|
          api_deserialiser.deserialise(Nomis::Movement, movement)
        }
      end

      # rubocop:enable Metrics/LineLength
      def self.admissions_for(offender_no)
        # admissions need to include transfers from one place to another
        route = '/elite2api/api/movements/offenders?movementTypes=ADM&movementTypes=TRN&latestOnly=false'

        cache_key = "#{route}#{offender_no}"

        Rails.cache.fetch(cache_key,
                          expires_in: Rails.configuration.cache_expiry) do
          data = e2_client.post(route, [offender_no])
          data.sort_by { |k| k['createDateTime'] }.map{ |movement|
            api_deserialiser.deserialise(Nomis::Movement, movement)
          }
        end
      end
    end
  end
end
