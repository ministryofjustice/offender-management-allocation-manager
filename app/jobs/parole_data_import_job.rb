require 'csv'

class ParoleDataImportJob < ApplicationJob
  queue_as :default

  def perform(date)
    Rails.logger = Logger.new($stdout) if Rails.env.production?

    import_parole(date)
    process_parole
  end

  def import_parole(date)
    log_prefix = 'job=parole_data_import_job,service=parole_data_import_service'

    if ENV['S3_BUCKET_NAME'].blank?
      Rails.logger.error("#{log_prefix},snapshot_date=#{date}|S3_BUCKET_NAME not set")
      return
    end

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Starting")

    purge_count = ParoleDataImportService.purge
    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|#{purge_count} records purged")

    import_count, row_count = ParoleDataImportService
      .new(log_prefix:)
      .import_with_catchup(date)

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Complete. #{import_count}/#{row_count} imported")
  end

  def process_parole
    log_prefix = 'job=parole_data_import_job,service=parole_data_process_service'
    Rails.logger.info("#{log_prefix}|Starting")
    ParoleDataProcessService.process
    Rails.logger.info("#{log_prefix}|Complete")
  end
end
