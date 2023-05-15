class DomainEvents::Event
  EVENT_TYPE_PREFIX = 'offender-management.'.freeze

  def initialize(event_type:,
                 version:,
                 description: nil,
                 detail_url: nil,
                 additional_information: nil,
                 noms_number: nil)
    full_event_type = "#{EVENT_TYPE_PREFIX}#{event_type}"

    @noms_number = noms_number

    @message_attributes = {
      'eventType' => {
        data_type: 'String',
        string_value: full_event_type,
      }
    }

    @message = {
      'eventType' => full_event_type,
      'version' => version,
      'description' => description,
      'detailUrl' => detail_url,
      'additionalInformation' => additional_information,
      'personReference' => noms_number ? { 'identifiers' => [{ 'type' => 'NOMS', 'value' => noms_number }] } : nil,
    }.compact
  end

  def publish(now: Time.zone.now.utc)
    full_message = @message.merge('occurredAt' => now.iso8601)
    self.class.json_validate!(full_message)

    message_data = {
      message_attributes: @message_attributes,
      message: ActiveSupport::JSON.encode(full_message),
    }
    sns_response = self.class.sns_topic.publish(message_data)
    Rails.logger.info "nomis_offender_id=#{@noms_number},domain_event=#{@message['eventType']},sns_message_id=#{sns_response.message_id},event=domain_event_published"
  end

  def self.sns_topic
    unless @sns_topic
      topic_arn = ENV.fetch('DOMAIN_EVENTS_TOPIC_ARN')
      aws_region = extract_region(topic_arn)
      @sns_topic = Aws::SNS::Resource.new(region: aws_region).topic(topic_arn)
    end

    @sns_topic
  end

  def self.extract_region(topic_arn)
    matches = /\Aarn:aws:sns:([a-z0-9-]+):/.match(topic_arn)
    raise ArgumentError, "bad topic #{topic_arn}" unless matches

    matches[1]
  end

  def self.json_validate!(data)
    @schema ||= ActiveSupport::JSON.decode(File.read(Rails.root.join('config', 'domain_events_message_schema.json')))

    JSON::Validator.validate!(@schema, data)
  end
end
