# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class MovementApi
      extend PrisonApiClient

      def self.movements_on_date(date)
        route = '/movements'

        data = e2_client.get(route, queryparams: {
                               movementDate: date.strftime('%F'),
                               fromDateTime: (date - 1.day).strftime('%FT%R')
                             })
        data.map { |movement|
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        }
      end

      def self.movements_for(offender_no)
        route = '/movements/offenders'

        data = e2_client.post(route, [offender_no], queryparams: { latestOnly: false, movementTypes: %w[ADM TRN REL] })
        data.sort_by { |k| k['createDateTime'] }.map { |movement|
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        }
      end

      def self.admissions_for(offender_nos)
        # admissions need to include transfers from one place to another
        route = '/movements/offenders'
        types = [HmppsApi::MovementType::ADMISSION,
                 HmppsApi::MovementType::TRANSFER].freeze

        cache_key = "#{route}_#{Digest::SHA256.hexdigest(offender_nos.to_s)}_#{types}"

        Rails.cache.fetch(cache_key,
                          expires_in: Rails.configuration.cache_expiry) do
          data = e2_client.post(route, offender_nos,
                                queryparams: { latestOnly: false, movementTypes: types }).
            group_by { |x| x['offenderNo'] }.values
          movements = data.map { |d|
            d.sort_by { |k| k['createDateTime'] }.map { |movement|
              api_deserialiser.deserialise(HmppsApi::Movement, movement)
            }
          }
          # return a hash of offender_no => [HmppsApi::Movement]
          movements.index_by { |m| m.first.offender_no }
        end
      end

      def self.latest_temp_movement_for(offender_nos)
        route = '/movements/offenders'
        types = [HmppsApi::MovementType::ADMISSION,
                 HmppsApi::MovementType::TRANSFER,
                 HmppsApi::MovementType::TEMPORARY].freeze

        cache_key = "#{route}_#{Digest::SHA256.hexdigest(offender_nos.to_s)}_#{types}"

        # 'data' is an array of arrays, with one array for each offenderNo
        data = Rails.cache.fetch(cache_key,
                                 expires_in: Rails.configuration.cache_expiry) do
          e2_client.post(route, offender_nos,
                         queryparams: { latestOnly: true, movementTypes: types }).
            group_by { |x| x['offenderNo'] }.values
        end

        # This reduces the data to the most recent per offender
        # (one array rather than an array of arrays)
        movements = data.map { |d|
          movement = d.max_by { |k| k['createDateTime'] }
          api_deserialiser.deserialise(HmppsApi::Movement, movement)
        }
        # filter out non-temp movements - so if the last movement was
        # not temp, the resulting array will not have an entry for that offender
        movements.select { |m| m.out? && m.temporary? }.index_by(&:offender_no)
      end
    end
  end
end
