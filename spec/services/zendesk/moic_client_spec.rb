require 'rails_helper'

RSpec.describe Zendesk::MOICClient do
  subject { described_class.instance }

  let(:url) { 'https://zendesk_api.com' }
  let(:username) { 'bob' }
  let(:password) { '123456' }

  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  before do
    allow(Rails.application.config).to receive(:zendesk_url).and_return('https://zendesk_api.com')
    allow(Rails.application.config).to receive(:zendesk_username).and_return('bob')
    allow(Rails.application.config).to receive(:zendesk_password).and_return('123456')
  end

  describe 'a valid instance' do
    it 'has a zendesk url' do
     expect(subject.request { |client| client.config.url }).to eq(url)
    end

    it 'has a zendesk username' do

      expect(subject.request { |client| client.config.username }).to eq username
    end

    it 'has a zendesk password' do
      subject.request { |client| expect(client.config.password).to eq(password) }
    end
  end

  describe '#request' do
    let(:pool) { double(ConnectionPool) }
    let(:block) do
      ->(_) {}
    end

    before do
      allow(ConnectionPool).to receive(:new).and_return(pool)
    end

    it 'yields the give block passing an instance of zendesk client' do
      expect(pool).to receive(:with).and_yield(instance_of(ZendeskAPI::Client))
      subject.request(&block)
    end
  end
end
