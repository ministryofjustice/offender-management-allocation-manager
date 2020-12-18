# frozen_string_literal: true

class RecalculateHandoverDateJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)
    return if offender.nil? || offender.sentenced? == false

    begin
      # Recalculate handover dates, which will trigger a push to the Community API after_save
      CalculatedHandoverDate.recalculate_for(offender)
    rescue Faraday::ClientError # rubocop:disable Lint/SuppressedException
      # Swallow Community API errors to allow this job to complete successfully.
      # The calculated handover date will not be saved, and we'll retry again in tomorrow night's cron.
      # Without this, bad data in nDelius will cause our retry queue to continually grow as fresh jobs
      # are queued every night alongside old failed jobs continually retrying.
    end
  end
end
