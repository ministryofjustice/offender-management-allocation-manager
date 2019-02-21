class MovementService
  # rubocop:disable Metrics/MethodLength
  def self.movements_on(date, direction_filters: [], type_filters: [])
    movements = Nomis::Elite2::Api.movements_on_date(date)

    if direction_filters.any?
      movements = filter_movements(movements, direction_filters, proc { |m|
        direction_filters.include?(m.direction_code)
      })
    end

    if type_filters.any?
      movements = filter_movements(movements, type_filters, proc { |m|
        type_filters.include?(m.movement_type)
      })
    end

    movements
  end
# rubocop:enable Metrics/MethodLength

private

  def self.filter_movements(movements, filters, filter_func)
    return movements if filters.empty?

    filters.each do
      movements = movements.select(&filter_func)
    end

    movements
  end
end
