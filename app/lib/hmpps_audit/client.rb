# frozen_string_literal: true

# See: https://github.com/ministryofjustice/hmpps-typescript-lib/tree/main/packages/audit-client
class HmppsAudit::Client
  def initialize(sqs_client: nil)
    @sqs_client = sqs_client
  end

  def publish(what:, who:, subject_type: nil, subject_id: nil, correlation_id: nil, details: nil)
    return unless FeatureFlags.hmpps_audit.enabled?

    message = HmppsAudit::Message.new(
      what:, who:, subject_type:, subject_id:, correlation_id:, details:
    )

    unless HostEnv.local?
      response = sqs_client.send_message(queue_url:, message_body: message.to_h.to_json)
    end

    log(:info, 'hmpps_audit', what: message.what, correlation_id: message.correlation_id, sqs_message_id: response&.message_id)
    response
  rescue Aws::SQS::Errors::ServiceError, Seahorse::Client::NetworkingError => e
    log(:error, 'hmpps_audit_failed', what:, correlation_id:, error_class: e.class.name)
    raise
  end

private

  def sqs_client
    @sqs_client ||= Aws::SQS::Client.new
  end

  def queue_url
    ENV.fetch('AUDIT_SQS_QUEUE_URL')
  end

  def log(level, event_name, **attributes)
    Rails.logger.public_send(
      level, "event=#{event_name}|#{attributes.compact.to_json}"
    )
  end
end
