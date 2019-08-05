class CustomStatsLoggingJob < ApplicationJob
  queue_as :default

  def perform
    # Just so that the test doesn't write to stdout
    if Rails.env.test?
      logger = LogStashLogger.new(type: :file, path: 'log/test.log')
    else
      logger = LogStashLogger.new(type: :stdout)
    end
    case_info_count = CaseInformation.count
    logger.info case_information_count: case_info_count
  end
end
