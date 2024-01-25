require 'net/imap'
require 'mail'
require 'csv'

class ParoleDataImportJob < ApplicationJob
  queue_as :default

  def perform(date)
    log_prefix = 'job=parole_data_import_job'

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Starting")

    purge_count = ParoleDataImportService.purge
    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|#{purge_count} records purged")

    import_count, row_count = ParoleDataImportService
      .new(log_prefix: log_prefix)
      .import_from_email(date)

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Complete. #{import_count}/#{row_count} imported")
  end
end
