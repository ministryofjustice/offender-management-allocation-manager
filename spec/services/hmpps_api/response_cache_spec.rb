require 'rails_helper'

describe HmppsApi::ResponseCache do
  subject { described_class.new('https://example.com') }

  let(:method) { :get }
  let(:route) { '/api/some/endpoint' }
  let(:queryparams) { { 'a' => '1' } }
  let(:extra_headers) { { 'Page-Limit' => '100' } }
  let(:body) { nil }

  let(:response) do
    instance_double(
      Faraday::Response,
      status: 200,
      body: '{"ok":true}',
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  before do
    allow(Rails).to receive(:cache).and_return(
      ActiveSupport::Cache.lookup_store(:memory_store)
    )
    Rails.cache.clear
  end

  describe '#read' do
    it 'returns nil when no cached entry exists' do
      expect(
        subject.read(method:, route:, queryparams:, extra_headers:, body:)
      ).to be_nil
    end
  end

  describe '#write' do
    it 'stores only status and body in cache' do
      subject.write(method:, route:, queryparams:, extra_headers:, body:, response:)

      key = subject.send(:cache_key, method:, route:, queryparams:, extra_headers:, body:)
      expect(Rails.cache.read(key)).to eq(
        'status' => 200,
        'body' => '{"ok":true}'
      )
    end

    it 'can be read back as a cached response object' do
      subject.write(method:, route:, queryparams:, extra_headers:, body:, response:)

      cached = subject.read(method:, route:, queryparams:, extra_headers:, body:)

      expect(cached).to be_a(HmppsApi::ResponseCache::CachedResponse)
      expect(cached.status).to eq(200)
      expect(cached.body).to eq('{"ok":true}')
    end
  end

  describe '#expire' do
    it 'removes an existing cache entry' do
      subject.write(method:, route:, queryparams:, extra_headers:, body:, response:)

      subject.expire(method:, route:, queryparams:, extra_headers:, body:)

      expect(
        subject.read(method:, route:, queryparams:, extra_headers:, body:)
      ).to be_nil
    end
  end

  describe 'cache key versioning' do
    it 'prefixes keys with the cache key version' do
      key = subject.send(:cache_key, method:, route:, queryparams:, extra_headers:, body:)

      expect(key).to start_with('hmpps_api_request_v2_')
    end
  end
end
