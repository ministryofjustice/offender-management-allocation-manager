class CustomStatsLoggingJob < ApplicationJob
  queue_as :default

  def perform
    logger = LogStashLogger.new(type: :stdout)
    case_info_count = CaseInformation.count
    logger.info case_information_count: case_info_count
  end
end
