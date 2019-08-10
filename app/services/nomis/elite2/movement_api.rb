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
          api_deserialiser.deserialise(Nomis::Models::Movement, movement)
        }
      end

      def self.movements_for(offender_no)
        route = '/elite2api/api/movements/offenders'

        data = e2_client.post(route, [offender_no])
        data.sort_by { |k| k['movementTime'] }.map{ |movement|
          if Nomis::Models::Movement.movement_types.include? movement['movementType']
            api_deserialiser.deserialise(Nomis::Models::Movement, movement)
          end
        }.compact
      end
    end
  end
end
