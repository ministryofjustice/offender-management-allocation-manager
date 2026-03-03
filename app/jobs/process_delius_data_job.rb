# frozen_string_literal: true

class ProcessDeliusDataJob < ApplicationJob
  # This is a retriable error, it is excluded from Sentry to avoid noise
  class ImportTransientError < StandardError; end

  queue_as :default

  # 5 retries (~10 min with exp backoff) is sufficient for transient issues
  sidekiq_options retry: 5

  self.log_arguments = false

  # identifiers can be a single id or an array of ids
  # identifier_type can be :nomis_offender_id (default), or :crn
  # trigger_method can be :batch (default), or :event
  def perform(identifiers, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil)
    identifiers = Array(identifiers)

    prefix = "job=process_delius_data_job,count=#{identifiers.size},identifier_type=#{identifier_type},trigger_method=#{trigger_method}"
    prefix += ",event_type=#{event_type}" if event_type

    logger.info("#{prefix},event=started")

    import_service = DeliusDataImportService.new(identifier_type:, trigger_method:, event_type:, logger:)

    identifiers.each do |identifier|
      import_service.process(identifier)
    end

    logger.info("#{prefix},event=finished")

    errors = import_service.errors
    return if errors.empty?

    failed_identifiers = errors.keys

    # When only some identifiers in a batch failed, re-enqueue a new job with just the failed ones
    if failed_identifiers.size < identifiers.size
      logger.info("#{prefix},event=re_enqueuing_failures,failed_count=#{failed_identifiers.size}/#{identifiers.size}")

      self.class.perform_later(
        failed_identifiers, identifier_type:, trigger_method:, event_type:
      )
    else
      # All identifiers failed, raise so Sidekiq retries the whole job with exponential backoff
      raise ImportTransientError, "#{prefix},event=retrying_failures|" + \
                                  errors.map { |id, msg| "#{id}: #{msg}" }.join('; ')
    end
  end
end
