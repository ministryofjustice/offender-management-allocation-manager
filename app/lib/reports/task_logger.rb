# frozen_string_literal: true

module Reports
  module TaskLogger
  module_function

    def configure!
      $stdout.sync = true
      Rails.logger = Logger.new($stdout)
      Rails.logger.level = :warn
    end

    def warn(report_name, message)
      Rails.logger.warn("#{Time.current.strftime('%Y-%m-%d %H:%M:%S.%3N')} [#{report_name}] #{message}")
    end
  end
end
