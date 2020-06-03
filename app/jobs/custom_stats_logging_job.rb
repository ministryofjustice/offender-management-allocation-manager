class CustomStatsLoggingJob < ApplicationJob
  queue_as :default

  def perform
    # Just so that the test doesn't write to stdout
    logger = if Rails.env.test?
               LogStashLogger.new(type: :file, path: 'log/test.log')
             else
               LogStashLogger.new(type: :stdout)
             end
    case_info_count = CaseInformation.count
    logger.info case_information_count: case_info_count
  end
end
