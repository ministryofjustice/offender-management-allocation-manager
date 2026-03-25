require 'rails_helper'

describe NotifyMailInterceptor do
  let(:message) { Mail::Message.new }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('ENV_NAME').and_return(env_name)
    described_class.delivering_email(message)
  end

  context 'when env name is `test`' do
    let(:env_name) { 'test' }

    it 'does not perform deliveries' do
      expect(message.perform_deliveries).to be(false)
    end
  end

  context 'when env name is `preprod`' do
    let(:env_name) { 'preprod' }

    it 'does not perform deliveries' do
      expect(message.perform_deliveries).to be(false)
    end
  end

  context 'when env name is `staging`' do
    let(:env_name) { 'staging' }

    it 'performs deliveries' do
      expect(message.perform_deliveries).to be(true)
    end
  end

  context 'when env name is `production`' do
    let(:env_name) { 'production' }

    it 'performs deliveries' do
      expect(message.perform_deliveries).to be(true)
    end
  end
end
