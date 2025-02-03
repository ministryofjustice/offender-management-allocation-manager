require 'net/imap'
require 'mail'
require 'csv'

class ParoleDataImportJob < ApplicationJob
  queue_as :default

  def perform(date)
    Rails.logger = Logger.new($stdout) if Rails.env.production?
    job_prefix = 'job=parole_data_import_job'

    import_parole(date, job_prefix)
    process_parole(job_prefix)
  end

  def import_parole(date, job_prefix)
    log_prefix = "#{job_prefix},service=parole_data_import_service"

    if ENV['GMAIL_USERNAME'].nil? || ENV['GMAIL_PASSWORD'].nil?
      Rails.logger.error("#{log_prefix},snapshot_date=#{date}|Gmail credentials not set")
      return
    end

    if ENV['PPUD_EMAIL_FROM'].blank?
      Rails.logger.error("#{log_prefix},snapshot_date=#{date}|PPUD_EMAIL_FROM not set")
      return
    end

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Starting")

    purge_count = ParoleDataImportService.purge
    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|#{purge_count} records purged")

    import_count, row_count = ParoleDataImportService
      .new(log_prefix: log_prefix)
      .import_from_email_with_catchup(date)

    Rails.logger.info("#{log_prefix},snapshot_date=#{date}|Complete. #{import_count}/#{row_count} imported")
  end

  def process_parole(job_prefix)
    log_prefix = "#{job_prefix},service=parole_data_process_service"
    Rails.logger.info("#{log_prefix}|Starting")
    ParoleDataProcessService.process
    Rails.logger.info("#{log_prefix}|Complete")
  end
end
