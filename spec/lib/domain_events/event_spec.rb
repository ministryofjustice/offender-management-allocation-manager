RSpec.describe DomainEvents::Event do
  subject(:event) { described_class.new }

  let(:now) { Time.new(2022, 6, 16, 15, 1, 44, 'Z') }
  let(:mock_env) { { 'DOMAIN_EVENTS_TOPIC_ARN' => topic_arn } }
  let(:aws_region) { "xx-regn-1" }
  let(:topic_arn) { "arn:aws:sns:#{aws_region}:11111111:topic-name" }
  let(:published_data) { {} }
  let(:sns_topic) do
    t = double :sns_topic
    allow(t).to receive(:publish) do |values|
      published_data.replace(values)
    end
    t
  end
  let(:sns_resource) { double :sns_resource, topic: sns_topic }

  before do
    stub_const('ENV', mock_env)
    allow(Aws::SNS::Resource).to receive_messages(new: sns_resource)
  end

  describe 'in all cases' do
    before do
      event.publish(now: now)
    end

    it 'is published to the domain events SNS topic' do
      aggregate_failures do
        expect(Aws::SNS::Resource).to have_received(:new).with(region: aws_region)
        expect(sns_resource).to have_received(:topic).with(topic_arn)
      end
    end

    it 'is published with an auto-generated timestamp' do
      timestamp = Time.zone.parse(published_data.fetch(:message).fetch("occurredAt"))
      expect(timestamp).to eq now
    end
  end

  describe 'when initialised with all available arguments' do
    it 'is published with the given event type in the message wrapper'
    it 'is published with the given event type in the message body'
    it 'is published with the given version'
    it 'is published with the given description text'
    it 'is published with the given detail URL'
    it 'is published with the given additional information'
    it 'is published with the given person reference'
  end

  describe 'when initialised with only required arguments' do
    it 'is published with the given event type in the message wrapper'
    it 'is published with the given event type in the message body'
    it 'is published with an auto-generated version'
  end

  describe 'message body schema validation' do
    it 'allows a valid message body to be published'

    it 'raises an error if attempting to publish a message with an invalid message body'
  end
end
