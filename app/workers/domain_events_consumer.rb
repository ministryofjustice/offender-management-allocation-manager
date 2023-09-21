class DomainEventsConsumer
  include Shoryuken::Worker

  shoryuken_options queue: ENV.fetch('DOMAIN_EVENTS_SQS_QUEUE_NAME', 'undefined'), auto_delete: true

  def perform(sqs_msg, sns_msg_raw)
    Shoryuken::Logging.logger.info "event=domain_event_consume_start,sqs_message_id=#{sqs_msg.message_id}"
    begin
      sns_msg = ActiveSupport::JSON.decode(sns_msg_raw)
      event_raw = ActiveSupport::JSON.decode(sns_msg.fetch('Message'))
      Shoryuken::Logging.logger.info "event=domain_event_consume_decoded,sqs_message_id=#{sqs_msg.message_id},sns_message_id=#{sns_msg['MessageId']}," \
                                     "event_type=#{event_raw['eventType']}"
      event = DomainEvents::Event.new(
        event_type: event_raw.fetch('eventType'),
        version: event_raw.fetch('version'),
        description: event_raw['description'],
        detail_url: event_raw['detailUrl'],
        additional_information: event_raw['additionalInformation'],
        noms_number: extract_identifier(event_raw, 'NOMS'),
        crn_number: extract_identifier(event_raw, 'CRN'),
        external_event: true,
      )
      consume(event)
      Shoryuken::Logging.logger.info "event=domain_event_consume_success,sqs_message_id=#{sqs_msg.message_id},sns_message_id=#{sns_msg['MessageId']}"
    rescue StandardError => e
      Shoryuken::Logging.logger.info "event=domain_event_consume_error|#{e.inspect},#{e.backtrace.join(',')}"
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

  def extract_identifier(event_raw, identifier_type)
    event_raw.fetch('identifiers', []).each { |i| return i.fetch('value') if i.fetch('type') == identifier_type }
    nil
  end
end
