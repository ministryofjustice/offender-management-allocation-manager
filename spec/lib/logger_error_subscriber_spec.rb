require 'rails_helper'

RSpec.describe LoggerErrorSubscriber do
  subject(:subscriber) { described_class.new }

  let(:error_reporter) { ActiveSupport::ErrorReporter.new(subscriber) }
  let(:exception) do
    StandardError.new('boom').tap do |error|
      error.set_backtrace(['/app/app/services/example.rb:12:in `call`'])
    end
  end

  before do
    allow(Rails.logger).to receive(:error)
    allow(Rails.logger).to receive(:warn)
    allow(Rails.logger).to receive(:info)
  end

  it 'logs reported errors with structured metadata' do
    subscriber.report(
      exception,
      handled: true,
      severity: :error,
      context: { tags: { domain_event: true }, request_id: 'abc123' },
      source: 'domain_events_consumer'
    )

    expect(Rails.logger).to have_received(:error).with(
      a_string_including(
        'event=rails_error_reported',
        'source=domain_events_consumer',
        'handled=true',
        'error_class=StandardError',
        'message=boom',
        'first_frame=/app/app/services/example.rb:12:in `call`'
      )
    )
  end

  it 'uses warn for warning severity' do
    subscriber.report(exception, handled: true, severity: :warning, context: {}, source: 'cache_store')

    expect(Rails.logger).to have_received(:warn).with(
      a_string_including('source=cache_store')
    )
  end

  it 'logs default handled and severity values without subscriber changes' do
    error_reporter.report(exception, source: 'cache_store')

    expect(Rails.logger).to have_received(:warn).with(
      a_string_including(
        'source=cache_store',
        'handled=true'
      )
    )
  end

  it 'logs default severity for unhandled errors' do
    error_reporter.report(exception, handled: false, source: 'exceptions_app')

    expect(Rails.logger).to have_received(:error).with(
      a_string_including(
        'source=exceptions_app',
        'handled=false'
      )
    )
  end
end
