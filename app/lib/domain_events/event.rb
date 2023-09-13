class DomainEvents::Event
  EVENT_TYPE_PREFIX = 'offender-management.'.freeze

  def initialize(event_type:,
                 version:,
                 description: nil,
                 detail_url: nil,
                 additional_information: nil,
                 noms_number: nil,
                 crn_number: nil,
                 external_event: false)
    full_event_type = external_event ? event_type : "#{EVENT_TYPE_PREFIX}#{event_type}"

    @noms_number = noms_number
    @crn_number = crn_number
    @short_event_type = event_type

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
      'personReference' => presonal_reference
    }.compact
  end

  attr_reader :noms_number, :crn_number, :message

  def event_type
    @message.fetch('eventType')
  end

  def additional_information
    @message['additionalInformation']
  end

  def description
    @message['description']
  end

  def detail_url
    @message['detailUrl']
  end

  def publish(now: Time.zone.now.utc, job: nil)
    full_message = @message.merge('occurredAt' => now.iso8601)
    self.class.json_validate!(full_message)

    message_data = {
      message_attributes: @message_attributes,
      message: ActiveSupport::JSON.encode(full_message),
    }
    sns_response = self.class.sns_topic.publish(message_data)

    audit_tags = ['domain_event_published', *@short_event_type.split('.')]
    audit_tags += ['job', job] if job
    AuditEvent.publish(
      nomis_offender_id: @noms_number,
      tags: audit_tags,
      system_event: true,
      data: {
        'sns_message_id' => sns_response.message_id,
        'domain_event' => full_message,
      }
    )
  end

  def self.sns_topic
    unless @sns_topic
      topic_arn = ENV.fetch('DOMAIN_EVENTS_TOPIC_ARN')
      aws_region = Utils::AwsUtils.extract_region_from_arn(topic_arn)
      localstack_url = ENV['LOCALSTACK_URL']
      client = Aws::SNS::Client.new(endpoint: localstack_url, region: aws_region) if localstack_url
      resource_params = { region: aws_region, client: client }.compact
      @sns_topic = Aws::SNS::Resource.new(**resource_params).topic(topic_arn)
    end

    @sns_topic
  end

  def self.json_validate!(data)
    @schema ||= ActiveSupport::JSON.decode(File.read(Rails.root.join('config', 'domain_events_message_schema.json')))

    JSON::Validator.validate!(@schema, data)
  end

private

  def presonal_reference
    return { 'identifiers' => [{ 'type' => 'NOMS', 'value' => noms_number }] } if noms_number
    return { 'identifiers' => [{ 'type' => 'CRN', 'value' => crn_number }] } if crn_number

    nil
  end
end
