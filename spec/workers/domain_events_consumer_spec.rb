RSpec.describe DomainEventsConsumer do
  subject(:consumer) { described_class.new }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.configuration.domain_event_handlers['testapp.domain.action'] = 'DomainEventTestHandler'
  end

  before do
    DomainEventTestHandler.clear_handled_events
  end

  it 'processes a full domain event' do
    sqs_msg = instance_double(Shoryuken::Message, message_id: 'sqs_msg_id')
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'TopicArn' => 'arn:::::',
      'Message' => {
        'eventType' => 'testapp.domain.action',
        'additionalInformation' => { 'foo' => 'bar' },
        'version' => '2',
        'description' => 'test_description',
        'detailUrl' => 'https://example.com/detail',
        'occurredAt' => '2023-08-10T12:15:30.598418329',
        'identifiers' => [
          { 'type' => 'NOMS', 'value' => 'X1111XX' },
        ],
      }.to_json,
      'MessageAttributes' => {
        'eventType' => {
          'Type' => 'String',
          'Value' => 'testapp.domain.action',
        },
      },
      'Timestamp' => '',
      'SignatureVersion' => '',
      'Signature' => '',
      'SigningCertURL' => '',
      'UnsubscribeURL' => '',
    }.to_json

    consumer.perform(sqs_msg, sns_msg_raw)
    event = DomainEventTestHandler.handled_events.fetch(0)

    aggregate_failures do
      expect(event.noms_number).to eq 'X1111XX'
      expect(event.message['eventType']).to eq 'testapp.domain.action'
      expect(event.message['additionalInformation']).to eq({ 'foo' => 'bar' })
      expect(event.message['version']).to eq '2'
      expect(event.message['description']).to eq 'test_description'
      expect(event.message['detailUrl']).to eq 'https://example.com/detail'
    end
  end

  it 'processes a minimal domain event' do
    sqs_msg = instance_double(Shoryuken::Message, message_id: 'sqs_msg_id')
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'TopicArn' => 'arn:::::',
      'Message' => {
        'eventType' => 'testapp.domain.action',
        'version' => '3',
        'occurredAt' => '2023-08-10T12:15:30.598418329',
      }.to_json,
      'MessageAttributes' => {
        'eventType' => {
          'Type' => 'String',
          'Value' => 'testapp.domain.action',
        },
      },
      'Timestamp' => '',
      'SignatureVersion' => '',
      'Signature' => '',
      'SigningCertURL' => '',
      'UnsubscribeURL' => '',
    }.to_json

    consumer.perform(sqs_msg, sns_msg_raw)
    event = DomainEventTestHandler.handled_events.fetch(0)

    aggregate_failures do
      expect(event.noms_number).to eq nil
      expect(event.message['eventType']).to eq 'testapp.domain.action'
      expect(event.message['additionalInformation']).to eq(nil)
      expect(event.message['version']).to eq '3'
      expect(event.message['description']).to eq nil
      expect(event.message['detailUrl']).to eq nil
    end
  end

  it 'does not handle unsupported events' do
    sqs_msg = instance_double(Shoryuken::Message, message_id: 'sqs_msg_id')
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'Message' => {
        'eventType' => 'testapp.domain.unsupported-action',
        'version' => '1',
        'occurredAt' => '2023-08-10T12:15:30.598418329',
      }.to_json,
    }.to_json

    consumer.perform(sqs_msg, sns_msg_raw)
    expect(DomainEventTestHandler.handled_events).to eq []
  end
end