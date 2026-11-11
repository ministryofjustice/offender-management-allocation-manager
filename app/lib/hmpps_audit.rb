# frozen_string_literal: true

module HmppsAudit
  CLIENT_MUTEX = Mutex.new

  def self.client
    CLIENT_MUTEX.synchronize { @client ||= Client.new }
  end

  def self.publish(what:, who:, subject_type:, correlation_id: nil, **attributes)
    return unless FeatureFlags.hmpps_audit.enabled?

    client.publish(
      what:, who:, subject_type:, correlation_id:, **attributes
    )
  rescue StandardError => e
    Rails.error.report(
      e, handled: true, severity: :error, source: 'hmpps_audit', context: { what:, correlation_id: }
    )
  end
end
