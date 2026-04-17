# frozen_string_literal: true

module Reports
  module TaskOptions
  module_function

    # Examples: 0.. | 0..60 | 61..
    def prisons_range
      start_index, end_index = ENV.fetch('PRISONS_RANGE', '0').split('..', 2)
      start_index = start_index.to_i

      end_index.present? ? (start_index..end_index.to_i) : (start_index..)
    end

    # Format for dates: 2026-02-16
    def date_range(default_from: 1.year.ago.to_date, default_to: Date.current)
      [
        Date.iso8601(ENV.fetch('DATE_FROM', default_from.iso8601)),
        Date.iso8601(ENV.fetch('DATE_TO', default_to.iso8601))
      ]
    end

    def filename(default)
      ENV.fetch('FILENAME', default)
    end
  end
end
