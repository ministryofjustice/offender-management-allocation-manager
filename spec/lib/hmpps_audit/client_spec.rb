RSpec.describe HmppsAudit::Client do
  subject(:client) { described_class.new(sqs_client:) }

  let(:sqs_client) { Aws::SQS::Client.new(region: 'eu-west-2', stub_responses: true) }
  let(:queue_url) { 'https://sqs.eu-west-2.amazonaws.com/123456789012/audit' }
  let(:event) do
    {
      what: 'VIEW_PRISONER',
      who: 'test-user',
      subject_type: 'PRISONER_ID',
      subject_id: 'A1234BC',
      correlation_id: 'request-123',
      details: { page: 'prisoner-profile' },
    }
  end

  before do
    allow(HostEnv).to receive(:local?).and_return(false)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('AUDIT_SQS_QUEUE_URL').and_return(queue_url)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    sqs_client.stub_responses(:send_message, message_id: 'message-123')
  end

  it 'sends the serialised message directly to SQS' do
    freeze_time do
      response = client.publish(**event)

      expect(response.message_id).to eq('message-123')
      expect(sqs_client.api_requests.last.fetch(:params)).to eq(
        queue_url:,
        message_body: HmppsAudit::Message.new(**event).to_h.to_json
      )
    end
  end

  it 'logs SQS acceptance without logging usernames, subjects or details' do
    client.publish(**event)

    expect(Rails.logger).to have_received(:info).with(
      'event=hmpps_audit|{"what":"VIEW_PRISONER","correlation_id":"request-123","sqs_message_id":"message-123"}'
    )
  end

  it 'allows omitted subject fields through the public API' do
    client.publish(what: 'LOGIN', who: 'test-user')

    payload = JSON.parse(sqs_client.api_requests.last.fetch(:params).fetch(:message_body))
    expect(payload).not_to have_key('subjectType')
    expect(payload).not_to have_key('subjectId')
  end

  it 'creates and reuses an AWS client using the SDK configuration' do
    allow(Aws::SQS::Client).to receive(:new).with(no_args).and_return(sqs_client)
    default_client = described_class.new

    2.times { default_client.publish(**event) }

    expect(Aws::SQS::Client).to have_received(:new).with(no_args).once
    expect(sqs_client.api_requests.size).to eq(2)
  end

  context 'when the feature flag is disabled' do
    before do
      allow(FeatureFlags).to receive(:hmpps_audit).and_return(double(enabled?: false))
    end

    it 'does not validate, fetch configuration, create a client or log' do
      expect(ENV).not_to receive(:fetch).with('AUDIT_SQS_QUEUE_URL')
      expect(Aws::SQS::Client).not_to receive(:new)

      expect(described_class.new.publish(**event.merge(who: nil))).to be_nil
      expect(Rails.logger).not_to have_received(:info)
    end
  end

  context 'when running locally' do
    before do
      allow(HostEnv).to receive(:local?).and_return(true)
    end

    it 'uses the same event log without configuration, AWS access or sensitive data' do
      expect(ENV).not_to receive(:fetch).with('AUDIT_SQS_QUEUE_URL')
      expect(Aws::SQS::Client).not_to receive(:new)

      expect(described_class.new.publish(**event)).to be_nil
      expect(Rails.logger).to have_received(:info).with(
        'event=hmpps_audit|{"what":"VIEW_PRISONER","correlation_id":"request-123"}'
      )
    end

    it 'still rejects invalid events' do
      expect { client.publish(**event.merge(who: nil)) }.to raise_error(ArgumentError, /who/)
    end
  end

  context 'when queue configuration is missing' do
    it 'raises rather than falling back to local logging' do
      allow(ENV).to receive(:fetch).with('AUDIT_SQS_QUEUE_URL').and_raise(KeyError)

      expect { client.publish(**event) }.to raise_error(KeyError)
      expect(sqs_client.api_requests).to be_empty
      expect(Rails.logger).not_to have_received(:info)
    end
  end

  [Aws::SQS::Errors::ServiceError.new(nil, 'failed'),
   Seahorse::Client::NetworkingError.new(IOError.new('connection failed'))].each do |error|
    it "logs and propagates #{error.class} without logging the payload" do
      sqs_client.stub_responses(:send_message, error)

      expect { client.publish(**event) }.to raise_error(error.class)
      expect(Rails.logger).to have_received(:error).with(
        "event=hmpps_audit_failed|#{{
          what: 'VIEW_PRISONER',
          correlation_id: 'request-123',
          error_class: error.class.name,
        }.to_json}"
      )
      expect(Rails.logger).not_to have_received(:info)
    end
  end

  it 'rejects invalid messages before sending or logging' do
    expect { client.publish(**event.merge(who: nil)) }.to raise_error(ArgumentError, /who/)
    expect(sqs_client.api_requests).to be_empty
    expect(Rails.logger).not_to have_received(:info)
  end
end
