class DomainEvents::Event
  def initialize
    topic_arn = ENV.fetch('DOMAIN_EVENTS_TOPIC_ARN')
    aws_region = self.class.extract_region(topic_arn)
    @sns_topic = Aws::SNS::Resource.new(region: aws_region).topic(topic_arn)
  end

  def publish(now: Time.zone.now)
    message_data = {
      message: {
        'occurredAt' => now.iso8601,
      },
    }
    @sns_topic.publish(message_data)
  end

  def self.extract_region(topic_arn)
    matches = /\Aarn:aws:sns:([a-z0-9-]+):/.match(topic_arn)
    raise ArgumentError, "bad topic #{topic_arn}" unless matches

    matches[1]
  end
end
