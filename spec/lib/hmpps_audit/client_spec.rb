RSpec.describe HmppsAudit::Client, :enable_hmpps_audit_publish do
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
    allow(HostEnv).to receive(:env_name).and_return(HostEnv::PREPROD)
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('AUDIT_SQS_QUEUE_URL').and_return(queue_url)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    sqs_client.stub_responses(:send_message, message_id: 'message-123')
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(100.0, 100.125)
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

  it 'logs delivery metadata and the failure reason without sensitive fields in preprod' do
    client.publish(**event.merge(
      what: 'VIEW_CASE_INFORMATION_FAILURE',
      details: { 'failureReason' => 'Resource not found', 'privateData' => 'must not be logged' }
    ))

    expect(Rails.logger).to have_received(:info).with(
      'event=hmpps_audit|{"what":"VIEW_CASE_INFORMATION_FAILURE","subject_type":"PRISONER_ID","correlation_id":"request-123","sqs_message_id":"message-123","failure_reason":"Resource not found","send_duration_ms":125.0}'
    )
  end

  HostEnv::NAMED_ENVIRONMENTS.each do |environment|
    it "logs the failure reason once and only exposes details outside protected environments in #{environment}" do
      allow(HostEnv).to receive(:env_name).and_return(environment)
      details = { 'page' => 'prisoner-profile', 'failureReason' => 'Resource not found' }

      client.publish(**event.merge(details:))

      expect(Rails.logger).to have_received(:info) do |line|
        attributes = JSON.parse(line.split('|', 2).last)
        if [HostEnv::PREPROD, HostEnv::PRODUCTION].include?(environment)
          expect(attributes).not_to have_key('details')
          expect(attributes.fetch('failure_reason')).to eq('Resource not found')
        else
          expect(attributes.fetch('details')).to eq(details)
          expect(attributes).not_to have_key('failure_reason')
        end
      end
    end
  end

  it 'includes details in staging delivery failure logs' do
    allow(HostEnv).to receive(:env_name).and_return(HostEnv::STAGING)
    sqs_client.stub_responses(:send_message, Aws::SQS::Errors::ServiceError.new(nil, 'failed'))

    expect { client.publish(**event) }.to raise_error(Aws::SQS::Errors::ServiceError)

    expect(Rails.logger).to have_received(:error) do |line|
      expect(JSON.parse(line.split('|', 2).last).fetch('details')).to eq('page' => 'prisoner-profile')
    end
  end

  it 'allows an omitted subject ID through the public API' do
    client.publish(what: 'LOGIN', who: 'test-user', subject_type: 'NOT_APPLICABLE')

    payload = JSON.parse(sqs_client.api_requests.last.fetch(:params).fetch(:message_body))
    expect(payload.fetch('subjectType')).to eq('NOT_APPLICABLE')
    expect(payload).not_to have_key('subjectId')
  end

  it 'requires the subject_type keyword' do
    expect { client.publish(**event.except(:subject_type)) }.to raise_error(ArgumentError, /subject_type/)
    expect(sqs_client.api_requests).to be_empty
  end

  it 'creates and reuses an AWS client with custom timeout and retry config' do
    options = { http_open_timeout: 3, http_read_timeout: 3, retry_mode: 'standard', max_attempts: 2 }
    allow(Aws::SQS::Client).to receive(:new).with(**options).and_return(sqs_client)
    default_client = described_class.new

    2.times { default_client.publish(**event) }

    expect(Aws::SQS::Client).to have_received(:new).with(**options).once
    expect(sqs_client.api_requests.size).to eq(2)
  end

  context 'when running locally' do
    before do
      allow(HostEnv).to receive(:env_name).and_return(HostEnv::LOCAL)
    end

    it 'logs details without configuration or AWS access' do
      expect(ENV).not_to receive(:fetch).with('AUDIT_SQS_QUEUE_URL')
      expect(Aws::SQS::Client).not_to receive(:new)

      expect(described_class.new.publish(**event)).to be_nil
      expect(Rails.logger).to have_received(:info).with(
        'event=hmpps_audit|{"what":"VIEW_PRISONER","subject_type":"PRISONER_ID","correlation_id":"request-123","details":{"page":"prisoner-profile"}}'
      )
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

  [
    [HostEnv::PREPROD, Aws::SQS::Errors::ServiceError.new(nil, 'failed')],
    [HostEnv::PRODUCTION, Seahorse::Client::NetworkingError.new(IOError.new('connection failed'))],
  ].each do |environment, error|
    it "logs and propagates #{error.class} without logging the payload in #{environment}" do
      allow(HostEnv).to receive(:env_name).and_return(environment)
      sqs_client.stub_responses(:send_message, error)

      expect { client.publish(**event) }.to raise_error(error.class)
      expect(Rails.logger).to have_received(:error).with(
        "event=hmpps_audit_error|#{{
          what: 'VIEW_PRISONER',
          subject_type: 'PRISONER_ID',
          correlation_id: 'request-123',
          error_class: error.class.name,
          send_duration_ms: 125.0,
        }.to_json}"
      )
      expect(Rails.logger).not_to have_received(:info)
    end
  end

  [HostEnv::LOCAL, HostEnv::STAGING].each do |environment|
    it "rejects invalid messages before sending or logging in #{environment}" do
      allow(HostEnv).to receive(:env_name).and_return(environment)

      expect { client.publish(**event.merge(who: nil)) }.to raise_error(ArgumentError, /who/)
      expect(sqs_client.api_requests).to be_empty
      expect(Rails.logger).not_to have_received(:info)
      expect(Rails.logger).not_to have_received(:error)
    end
  end
end
