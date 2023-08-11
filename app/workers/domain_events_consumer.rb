class DomainEventsConsumer
  include Shoryuken::Worker

  shoryuken_options queue: ENV.fetch('DOMAIN_EVENTS_SQS_QUEUE_NAME', 'undefined'), auto_delete: true

  def perform(sqs_msg, sns_msg_raw)
    Shoryuken::Logging.logger.info "event=domain_event_consume_start,sqs_message_id=#{sqs_msg.message_id}"
    begin
      sns_msg = ActiveSupport::JSON.decode(sns_msg_raw)
      Shoryuken::Logging.logger.info "event=domain_event_consume_decoded,sqs_message_id=#{sqs_msg.message_id},sns_message_id=#{sns_msg['MessageId']}|#{ActiveSupport::JSON.encode(sns_msg)}"
      event_raw = ActiveSupport::JSON.decode(sns_msg.fetch('Message'))
      event = DomainEvents::Event.new(
        event_type: event_raw.fetch('eventType'),
        version: event_raw.fetch('version'),
        description: event_raw['description'],
        detail_url: event_raw['detailUrl'],
        additional_information: event_raw['additionalInformation'],
        noms_number: extract_noms_number(event_raw),
        external_event: true,
      )
      consume(event)
      Shoryuken::Logging.logger.info "event=domain_event_consume_success,sqs_message_id=#{sqs_msg.message_id},sns_message_id=#{sns_msg['MessageId']}"
    rescue StandardError
      Shoryuken::Logging.logger.info "event=domain_event_consume_error|raw_sqs_msg: #{sqs_msg.inspect}, sns_msg_raw: #{sns_msg_raw.inspect}"
      raise
    end
  end

  def consume(event)
    handler_class_str = Rails.configuration.domain_event_handlers[event.event_type]
    return unless handler_class_str

    handler_class = handler_class_str.constantize
    handler = handler_class.new
    handler.handle(event)
  end

private

  def extract_noms_number(event_raw)
    event_raw.fetch('identifiers', []).each { |i| return i.fetch('value') if i.fetch('type') == 'NOMS' }
    nil
  end
end
