class MovementService
  # rubocop:disable Metrics/MethodLength
  def self.movements_on(date, direction_filters: [], type_filters: [])
    movements = Nomis::Elite2::MovementApi.movements_on_date(date)

    if direction_filters.any?
      movements = movements.select { |m|
        direction_filters.include?(m.direction_code)
      }
    end

    if type_filters.any?
      movements = movements.select { |m|
        type_filters.include?(m.movement_type)
      }
    end

    movements
  end
  # rubocop:enable Metrics/MethodLength
end
