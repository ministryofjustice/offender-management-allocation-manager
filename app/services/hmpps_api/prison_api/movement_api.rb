# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class MovementApi
      extend PrisonApiClient

      ADMISSION_TYPES = [HmppsApi::MovementType::ADMISSION,
                         HmppsApi::MovementType::TRANSFER].freeze

      def self.movements_on_date(date)
        route = '/movements'

        # the 'fromDateTime' field in the API is the 'earliest creation date' of a movement
        # obviously we have no idea how early this might be, so set it to last year so that they
        # are hopefully all caught.
        data = client.get(route, queryparams: {
          movementDate: date.strftime('%F'),
          fromDateTime: (date - 1.year).strftime('%FT%R')
        })
        data.map do |movement|
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        end
      end

      # This is only called by allocation history and debugging (to find the last movement)
      def self.movements_for(offender_no, movement_types = ADMISSION_TYPES)
        route = '/movements/offenders'

        data = client.post(route, [offender_no],
                           queryparams: { latestOnly: false, allBookings: true, movementTypes: movement_types },
                           cache: true)
        movements = data.sort_by { |k| k.fetch('movementDate') + k.fetch('movementTime') }.map do |movement|
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        end
        PrisonTimeline.new movements
      end

      def self.admissions_for(offender_nos)
        # admissions need to include transfers from one place to another
        route = '/movements/offenders'

        data = client.post(route, offender_nos,
                           queryparams: { latestOnly: false, movementTypes: ADMISSION_TYPES },
                           cache: true)
                     .group_by { |x| x['offenderNo'] }.values

        movements = data.map do |d|
          d.sort_by { |k| k['movementDate'] }.map do |movement|
            api_deserialiser.deserialise(HmppsApi::Movement, movement)
          end
        end
        # return a hash of offender_no => [HmppsApi::Movement]
        movements.index_by { |m| m.first.offender_no }
      end

      def self.latest_temp_movement_for(offender_nos)
        route = '/movements/offenders'
        types = [HmppsApi::MovementType::ADMISSION,
                 HmppsApi::MovementType::TRANSFER,
                 HmppsApi::MovementType::TEMPORARY].freeze

        # 'data' is an array of arrays, with one array for each offenderNo
        data = client.post(route, offender_nos,
                           queryparams: { latestOnly: true, movementTypes: types },
                           cache: true)
                     .group_by { |x| x['offenderNo'] }.values

        # This reduces the data to the most recent per offender
        # (one array rather than an array of arrays)
        movements = data.map do |d|
          movement = d.max_by { |k| k['movementDate'] }
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        end
        # filter out non-temp movements - so if the last movement was
        # not temp, the resulting array will not have an entry for that offender
        movements.select { |m| m.out? && m.temporary? }.index_by(&:offender_no)
      end
    end
  end
end
