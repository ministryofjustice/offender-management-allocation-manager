# frozen_string_literal: true

require_relative '../application_service'

module MovementService
  class MovementsOn < ApplicationService
    attr_reader :date, :direction_filters, :type_filters

    def initialize(date, direction_filters: [], type_filters: [])
      @date = date
      @direction_filters = direction_filters
      @type_filters = type_filters
    end

    def call
      movements = Nomis::Elite2::MovementApi.movements_on_date(@date)

      if @direction_filters.any?
        movements = movements.select { |m|
          @direction_filters.include?(m.direction_code)
        }
      end

      if @type_filters.any?
        movements = movements.select { |m|
          @type_filters.include?(m.movement_type)
        }
      end

      movements
    end
  end
end
