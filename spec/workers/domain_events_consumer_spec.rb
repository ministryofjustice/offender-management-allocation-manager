RSpec.describe DomainEventsConsumer do
  subject(:consumer) { described_class.new }

  before(:all) do # rubocop:disable RSpec/BeforeAfterAll
    Rails.configuration.domain_event_handlers['testapp.domain.action'] = 'DomainEventTestHandler'
  end

  before do
    DomainEventTestHandler.clear_handled_events
  end

  let(:sqs_msg) do
    instance_double(Shoryuken::Message,
                    message_id: 'sqs_msg_id',
                    attributes: { 'ApproximateReceiveCount' => '1' }
                   )
  end

  it 'processes a full domain event' do
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'TopicArn' => 'arn:::::',
      'Message' => {
        'eventType' => 'testapp.domain.action',
        'additionalInformation' => { 'foo' => 'bar' },
        'version' => 2,
        'description' => 'test_description',
        'detailUrl' => 'https://example.com/detail',
        'occurredAt' => '2023-08-10T12:15:30.59Z',
        'personReference' => {
          'identifiers' => [
            { 'type' => 'NOMS', 'value' => 'X1111XX' },
            { 'type' => 'CRN', 'value' => 'CRN001' },
          ]
        }
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
      expect(event.crn_number).to eq 'CRN001'
      expect(event.message['eventType']).to eq 'testapp.domain.action'
      expect(event.message['additionalInformation']).to eq({ 'foo' => 'bar' })
      expect(event.message['version']).to eq 2
      expect(event.message['description']).to eq 'test_description'
      expect(event.message['detailUrl']).to eq 'https://example.com/detail'
    end
  end

  it 'processes a minimal domain event' do
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'TopicArn' => 'arn:::::',
      'Message' => {
        'eventType' => 'testapp.domain.action',
        'version' => 3,
        'occurredAt' => '2023-08-10T12:15:30.59Z',
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
      expect(event.message['version']).to eq 3
      expect(event.message['description']).to eq nil
      expect(event.message['detailUrl']).to eq nil
    end
  end

  it 'does not handle unsupported events' do
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'Message' => {
        'eventType' => 'testapp.domain.unsupported-action',
        'version' => 1,
        'occurredAt' => '2023-08-10T12:15:30.59Z',
      }.to_json,
    }.to_json

    consumer.perform(sqs_msg, sns_msg_raw)
    expect(DomainEventTestHandler.handled_events).to eq []
  end

  it 'skips events if they have no eventType' do
    sns_msg_raw = {
      'Type' => 'Notification',
      'MessageId' => 'sns_msg_id',
      'Message' => {
        'version' => 1,
        'occurredAt' => '2023-08-10T12:15:30.59Z',
      }.to_json,
    }.to_json

    expect { consumer.perform(sqs_msg, sns_msg_raw) }.not_to raise_error
    expect(DomainEventTestHandler.handled_events).to eq []
  end
end
