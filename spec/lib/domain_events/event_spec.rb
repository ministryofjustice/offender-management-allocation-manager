RSpec.describe DomainEvents::Event do
  subject(:basic_event) { described_class.new(event_type: 'test-domain.changed', version: 77) }

  let(:full_event) do
    described_class.new(event_type: 'test-domain.full-event',
                        version: 8,
                        noms_number: 'X1111XX',
                        crn_number: 'X08769',
                        additional_information: { 'key1' => 'value1' },
                        description: 'event_description',
                        detail_url: 'https://example.com/event_detail_url')
  end

  let(:now) { Time.new(2022, 6, 16, 15, 1, 44, 'Z') }
  let(:mock_env) { ENV.to_hash.merge('DOMAIN_EVENTS_TOPIC_ARN' => topic_arn, 'LOCALSTACK_URL' => nil) }
  let(:aws_region) { "xx-regn-1" }
  let(:topic_arn) { "arn:aws:sns:#{aws_region}:11111111:topic-name" }
  let(:published_data) { {} }
  let(:sns_topic) do
    t = double :sns_topic
    allow(t).to receive(:publish) do |values|
      published_data.replace(values)
      double(:sns_response, message_id: 'fake-uuid')
    end
    t
  end
  let(:sns_resource) { double :sns_resource, topic: sns_topic }

  def published_message
    ActiveSupport::JSON.decode(published_data.fetch(:message, 'null'))
  end

  before do
    stub_const('ENV', mock_env)
    allow(Aws::SNS::Resource).to receive_messages(new: sns_resource)
    allow(AuditEvent).to receive(:publish)
  end

  after do
    # Remove the memoized sns_topic that the ::sns_topic method creates
    described_class.remove_instance_variable(:@sns_topic) if described_class.instance_variable_defined?(:@sns_topic)
  end

  shared_examples 'common examples' do
    it 'is published to the domain events SNS topic' do
      aggregate_failures do
        expect(Aws::SNS::Resource).to have_received(:new).with(region: aws_region)
        expect(sns_resource).to have_received(:topic).with(topic_arn)
      end
    end

    it 'is published with an auto-generated timestamp' do
      timestamp = Time.zone.parse(published_message.fetch("occurredAt"))
      expect(timestamp).to eq now
    end

    it 'is published with the given event type in the message wrapper' do
      expect(published_data.dig(:message_attributes, 'eventType'))
        .to eq({ data_type: 'String', string_value: 'offender-management.test-domain.changed' })
    end

    it 'is published with the given event type in the message body' do
      expect(published_message.fetch('eventType')).to eq 'offender-management.test-domain.changed'
    end

    it 'is published with the given version' do
      expect(published_message.fetch('version')).to eq 77
    end
  end

  describe 'when used with minimal arguments' do
    before do
      basic_event.publish(now: now)
    end

    it_behaves_like 'common examples'

    it 'only has required message attributes' do
      expect(published_message.keys).to match_array(%w[eventType occurredAt version])
    end

    it 'produces an audit event when published with sensible tag names' do
      expect(AuditEvent).to have_received(:publish).with(
        nomis_offender_id: nil,
        system_event: true,
        tags: %w[domain_event_published test-domain changed],
        data: {
          'sns_message_id' => 'fake-uuid',
          'domain_event' => published_message,
        },
      )
    end
  end

  describe 'when used with all available arguments' do
    before do
      event = described_class.new(event_type: 'test-domain.changed',
                                  version: 77,
                                  description: 'Test event',
                                  detail_url: 'https://example.com/r/1',
                                  additional_information: { 'dataA' => 'valueX' },
                                  noms_number: 'X1111XX',
                                  crn_number: 'X08769')
      event.publish(now: now, job: 'test_job')
    end

    it_behaves_like 'common examples'

    it 'is published with the given description text' do
      expect(published_message.fetch('description')).to eq 'Test event'
    end

    it 'is published with the given detail URL' do
      expect(published_message.fetch('detailUrl')).to eq 'https://example.com/r/1'
    end

    it 'is published with the given additional information' do
      expect(published_message.fetch('additionalInformation')).to eq('dataA' => 'valueX')
    end

    it 'is published with the given NOMS number and CRN in the person reference' do
      expect(published_message.fetch('personReference'))
        .to eq('identifiers' => [
          { 'type' => 'NOMS', 'value' => 'X1111XX' },
          { 'type' => 'CRN', 'value' => 'X08769' }
        ])
    end

    it 'produces an audit event when published with sensible tag names including job name, nomis_offender_id' do
      expect(AuditEvent).to have_received(:publish).with(
        nomis_offender_id: 'X1111XX',
        system_event: true,
        tags: %w[domain_event_published test-domain changed job test_job],
        data: {
          'sns_message_id' => 'fake-uuid',
          'domain_event' => published_message,
        },
      )
    end
  end

  describe 'message body schema validation' do
    it 'allows a valid message body to be published' do
      expect { basic_event.publish(now: now) }.not_to raise_error
    end

    it 'raises an error if attempting to publish a message with an invalid message body' do
      # Schema validates that version is an integer
      invalid_event = described_class.new(event_type: 'test-domain.changed', version: 'alpha')
      expect { invalid_event.publish(now: now) }.to raise_error(JSON::Schema::ValidationError, %r{#/version})
    end
  end

  describe 'for events from other apps' do
    it 'does not prefix offender-management. to the type' do
      described_class.new(event_type: 'otherapp.test-domain.changed', version: 77, external_event: true).publish
      expect(published_message.fetch('eventType')).to eq 'otherapp.test-domain.changed'
    end
  end

  describe 'interface' do
    it 'has #noms_number', :aggregate_failures do
      expect(basic_event.noms_number).to eq nil
      expect(full_event.noms_number).to eq 'X1111XX'
    end

    it 'has #crn_number', :aggregate_failures do
      expect(basic_event.crn_number).to eq nil
      expect(full_event.crn_number).to eq 'X08769'
    end

    it 'has #event_type' do
      expect(full_event.event_type).to eq 'offender-management.test-domain.full-event'
    end

    it 'has #additional_information', :aggregate_failures do
      expect(basic_event.additional_information).to eq nil
      expect(full_event.additional_information).to eq({ 'key1' => 'value1' })
    end

    it 'has #description', :aggregate_failures do
      expect(basic_event.description).to eq nil
      expect(full_event.description).to eq('event_description')
    end

    it 'has #detail_url', :aggregate_failures do
      expect(basic_event.detail_url).to eq nil
      expect(full_event.detail_url).to eq('https://example.com/event_detail_url')
    end
  end
end
