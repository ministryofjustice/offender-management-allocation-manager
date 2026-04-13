# frozen_string_literal: true

class HandoverReminderBatchJob < ApplicationJob
  queue_as :mailers

  # Email content can become stale; avoid retrying for days
  sidekiq_options retry: 10

  def perform(for_date = Time.zone.today)
    Handover::HandoverEmailBatchRun.send_all(for_date:)
  end
end
