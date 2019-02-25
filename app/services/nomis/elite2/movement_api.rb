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
    end
  end
end
