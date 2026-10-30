# frozen_string_literal: true

# See: https://github.com/ministryofjustice/hmpps-typescript-lib/tree/main/packages/audit-client
class HmppsAudit::Client
  def initialize(sqs_client: nil)
    @sqs_client = sqs_client
  end

  def publish(what:, who:, subject_type:, subject_id: nil, correlation_id: nil, details: nil)
    message = HmppsAudit::Message.new(
      what:, who:, subject_type:, subject_id:, correlation_id:, details:
    )

    log_attributes = {
      what:, subject_type:, correlation_id:, details: (details unless HostEnv.preprod? || HostEnv.production?),
    }

    unless HostEnv.local?
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        response = sqs_client.send_message(queue_url:, message_body: message.to_h.to_json)
      ensure
        send_duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(2)
      end
    end

    log(
      :info, 'hmpps_audit', **log_attributes,
      sqs_message_id: response&.message_id,
      failure_reason: (details&.fetch('failureReason', nil) unless log_attributes[:details]),
      send_duration_ms:
    )
    response
  rescue Aws::SQS::Errors::ServiceError, Seahorse::Client::NetworkingError => e
    log(:error, 'hmpps_audit_error', **log_attributes, error_class: e.class.name, send_duration_ms:)
    raise
  end

private

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new(
      http_open_timeout: 3,
      http_read_timeout: 3,
      retry_mode: 'standard',
      max_attempts: 2,
    )
  end

  def queue_url
    ENV.fetch('AUDIT_SQS_QUEUE_URL')
  end

  def log(level, event_name, **attributes)
    Rails.logger.public_send(
      level, "event=#{event_name}|#{attributes.compact_blank.to_json}"
    )
  end
end
