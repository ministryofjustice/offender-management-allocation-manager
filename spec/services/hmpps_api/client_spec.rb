require 'rails_helper'

describe HmppsApi::Client do
  let(:api_host) { Rails.configuration.prison_api_host }
  let(:client) { described_class.new(api_host) }
  let(:token_service) { HmppsApi::Oauth::TokenService }
  let(:access_token) { "access_token" }
  let(:valid_token) { HmppsApi::Oauth::Token.new(access_token: access_token) }

  let(:auth_header) do
    {
      headers: {
        'Authorization': "Bearer #{access_token}"
      }
    }
  end

  before do
    allow(token_service).to receive(:valid_token).and_return(valid_token)
  end

  describe 'with a valid request' do
    it 'sets the Authorization header' do
      WebMock.stub_request(:get, /\w/).to_return(body: '{}')

      username = 'MOIC_POM'
      route = "/api/users/#{username}"
      client.get(route)

      expect(WebMock).to have_requested(:get, /\w/)
        .with(auth_header)
    end
  end

  describe 'when a HTTP error response is received' do
    let(:status) { nil }
    let(:route) { '/api/endpoint' }

    before do
      WebMock.stub_request(:get, api_host + route)
        .to_return(status: status)
    end

    describe 'a 401 error' do
      let(:status) { 401 }

      it 'raises a HmppsApi::Error::Unauthorized error' do
        expect { client.get(route) }
          .to raise_error(HmppsApi::Error::Unauthorized, "the server responded with status #{status}")
      end
    end

    describe 'a 4xx error' do
      let(:status) { 403 }

      it 'raises a Faraday::ClientError error' do
        expect { client.get(route) }
          .to raise_error(Faraday::ClientError, "the server responded with status #{status}")
      end
    end

    describe '404 Not Found' do
      let(:status) { 404 }

      it 'raises a Faraday::ResourceNotFound error' do
        expect { client.get(route) }
          .to raise_error(Faraday::ResourceNotFound, "the server responded with status #{status}")
      end
    end

    describe 'a 5xx error' do
      let(:status) { 500 }

      it 'raises the correct error' do
        expect { client.get(route) }
          .to raise_error(Faraday::ServerError, "the server responded with status #{status}")
      end
    end
  end

  describe 'when the request times out' do
    let(:route) { '/api/endpoint' }

    before do
      WebMock.stub_request(:get, api_host + route)
        .to_timeout
    end

    it 'raises a Faraday::TimeoutError' do
      expect { client.get(route) }
        .to raise_error(Faraday::TimeoutError, 'request timed out')
    end
  end

  describe 'instance method' do
    let(:route) { '/api/some/endpoint' }
    let(:stub_url) { api_host + route }
    let(:response_body) { '{"key": "value", "success": true}' }

    shared_examples 'handles JSON response' do
      it 'decodes the response JSON' do
        expect(response).to be_a(Hash)
        expect(response).to eq JSON.parse(response_body)
      end
    end

    describe '#get' do
      let(:response) do
        client.get(route)
      end

      before do
        WebMock.stub_request(:get, stub_url)
          .to_return(body: response_body)

        # Trigger the request
        response
      end

      it 'performs an authenticated GET request' do
        expect(WebMock).to have_requested(:get, stub_url)
          .with(auth_header)
      end

      include_examples 'handles JSON response'

      describe 'request caching' do
        let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

        before do
          # Set up a cache store for these tests
          allow(Rails).to receive(:cache).and_return(memory_store)
          Rails.cache.clear
          WebMock.reset_executed_requests!
        end

        it 'caches responses by default' do
          5.times { client.get(route) }
          expect(a_request(:get, stub_url)).to have_been_made.once
        end

        context 'with cache: true' do
          it 'caches responses' do
            5.times { client.get(route, cache: true) }
            expect(a_request(:get, stub_url)).to have_been_made.once
          end
        end

        context 'with cache: false' do
          it 'does not cache responses' do
            5.times { client.get(route, cache: false) }
            expect(a_request(:get, stub_url)).to have_been_made.times(5)
          end
        end
      end
    end

    describe '#post' do
      let(:request_body) { { id: 123, someKey: 'Some value' } }
      let(:response) do
        client.post(route, request_body)
      end

      before do
        WebMock.stub_request(:post, stub_url)
          .to_return(body: response_body)

        # Trigger the request
        response
      end

      it 'performs an authenticated POST request' do
        expect(WebMock).to have_requested(:post, stub_url)
          .with(auth_header)
      end

      it 'encodes the request body as JSON' do
        expect(WebMock).to have_requested(:post, stub_url)
          .with(
            headers: {
              'Content-Type': 'application/json'
            },
            body: request_body.to_json
          )
      end

      include_examples 'handles JSON response'

      describe 'request caching' do
        let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

        before do
          # Set up a cache store for these tests
          allow(Rails).to receive(:cache).and_return(memory_store)
          Rails.cache.clear
          WebMock.reset_executed_requests!
        end

        it 'does not cache responses by default' do
          5.times { client.post(route, request_body) }
          expect(a_request(:post, stub_url)).to have_been_made.times(5)
        end

        context 'with cache: true' do
          it 'caches responses' do
            5.times { client.post(route, request_body, cache: true) }
            expect(a_request(:post, stub_url)).to have_been_made.once
          end
        end

        context 'with cache: false' do
          it 'does not cache responses' do
            5.times { client.post(route, request_body, cache: false) }
            expect(a_request(:post, stub_url)).to have_been_made.times(5)
          end
        end
      end
    end

    describe '#put' do
      let(:request_body) { { id: 123, someKey: 'Some value' } }
      let(:response) do
        client.put(route, request_body)
      end

      before do
        WebMock.stub_request(:put, stub_url)
          .to_return(body: response_body)

        # Trigger the request
        response
      end

      it 'performs an authenticated PUT request' do
        expect(WebMock).to have_requested(:put, stub_url)
          .with(auth_header)
      end

      it 'encodes the request body as JSON' do
        expect(WebMock).to have_requested(:put, stub_url)
          .with(
            headers: {
              'Content-Type': 'application/json'
            },
            body: request_body.to_json
          )
      end

      include_examples 'handles JSON response'
    end

    describe '#delete' do
      before do
        WebMock.stub_request(:delete, stub_url)
          .to_return(status: 200)

        client.delete(route)
      end

      it 'performs an authenticated DELETE request' do
        expect(WebMock).to have_requested(:delete, stub_url)
          .with(auth_header)
      end
    end
  end

  describe 'request caching' do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

    let(:base_request) do
      {
        root: 'https://example.com',
        route: '/some/endpoint',
        queryparams: {},
        extra_headers: {},
        body: nil,
        # HTTP methods to test caching for – we support caching both GET and POST requests
        methods: [:get, :post],
      }
    end

    # Helper to send a request
    def send_request(req)
      client = described_class.new(req[:root])

      if req[:method] == :get
        client.get(req[:route], queryparams: req[:queryparams], extra_headers: req[:extra_headers])
      else
        client.post(req[:route], req[:body],
                    queryparams: req[:queryparams], extra_headers: req[:extra_headers], cache: true)
      end
    end

    before do
      # Set up a cache store for these tests
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear

      # Stub all HTTP requests and return a unique response for each
      counter = 0
      WebMock.stub_request(:any, /.*/)
             .to_return { |_req| { body: ["Response #{counter += 1}"].to_json } }

      # Warm up the cache by sending each request once
      requests.each do |req|
        send_request(req)
      end
    end

    context 'when the requests are different' do
      # An array of requests to send – each one differing slightly
      let(:requests) do
        requests = [
          # A base request
          base_request,

          # Change the Root URL (e.g. API hostname)
          base_request.merge(root: 'https://some-other-hostname.com'),

          # Change the route (e.g. API endpoint)
          base_request.merge(route: '/a/different/endpoint'),

          # Change the query string parameters
          base_request.merge(queryparams: { movementTypes: %w[one two] }),

          # Send additional headers
          base_request.merge(extra_headers: { 'Page-Limit' => 100 }),

          # Send something in the request body – this is only supported for POST requests
          base_request.merge(body: ['a json array', 'in the request body'], methods: [:post]),
        ]

        # Make one request for each HTTP method (GET, POST)
        get_requests = requests.select { |req| req[:methods].include?(:get) }.map { |req| req.merge(method: :get) }
        post_requests = requests.select { |req| req[:methods].include?(:post) }.map { |req| req.merge(method: :post) }

        get_requests + post_requests
      end

      it 'caches them independently' do
        # Perform each request and keep the response
        responses = requests.map do |req|
          send_request(req)
        end

        expected_responses = (1..requests.length).map { |n| ["Response #{n}"] }

        # Expect: Response 1, Response 2, Response 3, etc...
        expect(responses).to eq(expected_responses)

        # Unique responses mean each request was cached independently - they didn't share a cache
        expect(responses.count).to eq(responses.uniq.count)
      end
    end

    context 'when the requests are the same' do
      # An array of 5 identical GET requests
      let(:requests) do
        [base_request.merge(method: :get)] * 5
      end

      it 'reuses the existing cache' do
        # Perform each request and keep the response
        responses = requests.map do |req|
          send_request(req)
        end

        # Expect cached "Response 1" to be returned 5 times
        expect(responses).to eq([['Response 1']] * 5)

        # Expect only 1 unique response – subsequent requests get the cached response
        expect(responses.uniq.count).to eq(1)
      end
    end
  end

  describe 'expiring cache' do
    let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }
    let(:route) { '/api/some/endpoint' }
    let(:stub_url) { api_host + route }
    let(:response_body) { '{"key": "value"}' }

    before do
      allow(Rails).to receive(:cache).and_return(memory_store)
      Rails.cache.clear
      WebMock.stub_request(:get, stub_url).to_return(body: response_body)
    end

    it 'removes the cached response for a request' do
      # Prime the cache
      client.get(route)
      expect(a_request(:get, stub_url)).to have_been_made.once

      # Expire the cache
      client.expire_cache_key(:get, route)

      # Next request should hit the API again
      client.get(route)
      expect(a_request(:get, stub_url)).to have_been_made.twice
    end
  end
end
