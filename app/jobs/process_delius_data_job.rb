# frozen_string_literal: true

class ProcessDeliusDataJob < ApplicationJob
  queue_as :default

  self.log_arguments = false

  # identifiers can be a single id (`crn` or `nomis_id`) or an array of ids
  # identifier_type can be :nomis_offender_id (default), or :crn
  # trigger_method can be :batch (default), or :event
  def perform(identifiers, identifier_type: :nomis_offender_id, trigger_method: :batch, event_type: nil)
    identifiers = Array(identifiers)

    prefix = "job=process_delius_data_job,count=#{identifiers.size},identifier_type=#{identifier_type},trigger_method=#{trigger_method}"
    prefix += ",event_type=#{event_type}" if event_type

    logger.info("#{prefix},event=started")

    identifiers.each do |identifier|
      DeliusDataImportService.new.process(identifier, identifier_type:, trigger_method:, event_type:)
    end

    logger.info("#{prefix},event=finished")
  end
end
