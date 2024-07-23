class DomainEventsConsumer
  include Shoryuken::Worker

  shoryuken_options queue: ENV.fetch('DOMAIN_EVENTS_SQS_QUEUE_NAME', 'undefined'),
                    auto_delete: true,
                    retry_intervals: [15.minutes, 1.hour]

  def perform(sqs_msg, sns_msg_raw)
    log sqs_msg, 'start'

    begin
      sns_msg = ActiveSupport::JSON.decode(sns_msg_raw)
      event_type = sns_msg.dig('MessageAttributes', 'eventType', 'Value')

      if event_type.blank?
        log sqs_msg, 'skip', append: "reason=missing_event_type,sns_message_id=#{sns_msg['MessageId']}"
        return
      end

      event_raw = ActiveSupport::JSON.decode(sns_msg.fetch('Message'))

      log sqs_msg, 'decoded', append: "sns_message_id=#{sns_msg['MessageId']},event_type=#{event_type}"

      event = DomainEvents::Event.new(
        event_type:,
        version: event_raw['version'],
        description: event_raw['description'],
        detail_url: event_raw['detailUrl'],
        additional_information: event_raw['additionalInformation'],
        noms_number: extract_identifier(event_raw, 'NOMS'),
        crn_number: extract_identifier(event_raw, 'CRN').presence || event_raw['crn'].presence,
        external_event: true,
      )

      consume(event)

      log sqs_msg, 'success', append: "sns_message_id=#{sns_msg['MessageId']},event_type=#{event_type}"
    rescue StandardError => e
      log sqs_msg, 'error', append: "reason=exception|#{e.inspect},#{e.backtrace.join(',')}", brief: true
      Sentry.capture_exception(e,
                               tags: {
                                 domain_event: true,
                                 domain_event_type: event_type,
                               })
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
    event_raw.fetch('personReference', {}).fetch('identifiers', []).each do |i|
      return i.fetch('value') if i.fetch('type') == identifier_type
    end

    nil
  end

  def log(sqs_msg, log_event_name, append: nil, brief: false)
    message_parts = [
      "event=domain_event_consume_#{log_event_name}",
      brief ? nil : "sqs_message_id=#{sqs_msg.message_id}",
      brief ? nil : "sqs_message_receive_count=#{sqs_msg.attributes['ApproximateReceiveCount']}",
      append
    ]

    Shoryuken::Logging.logger.info message_parts.compact.join(',')
  end
end
