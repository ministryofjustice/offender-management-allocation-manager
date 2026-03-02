# frozen_string_literal: true

class ProcessDeliusDataJob < ApplicationJob
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

    failed_identifiers = import_service.failed_identifiers
    return if failed_identifiers.empty?

    # When only some identifiers in a batch failed, re-enqueue a new job with just the failed ones
    if failed_identifiers.size < identifiers.size
      logger.info("#{prefix},event=re_enqueuing_failures,failed_count=#{failed_identifiers.size}")

      self.class.perform_later(
        failed_identifiers, identifier_type:, trigger_method:, event_type:
      )
    else
      # All identifiers failed, raise so Sidekiq retries the whole job with exponential backoff
      raise "All #{failed_identifiers.size} identifier(s) failed to process"
    end
  end
end
