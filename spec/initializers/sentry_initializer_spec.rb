require 'rails_helper'

RSpec.describe 'Sentry initializer' do
  let(:initializer_path) { Rails.root.join('config/initializers/sentry.rb') }
  let(:fake_sentry_config_class) do
    Struct.new(:dsn, :release, :enable_metrics, :before_send, :excluded_exceptions, :rails, keyword_init: true)
  end
  let(:fake_event_class) { Struct.new(:extra, :user, :contexts) }
  let(:rails_config) do
    double('rails_config', register_error_subscriber: nil, report_rescued_exceptions: nil)
  end
  let(:config) { fake_sentry_config_class.new(excluded_exceptions: [], rails: rails_config) }
  let(:event) do
    fake_event_class.new(
      { system_admin_note: 'secret', visible: 'keep me' },
      { system_admin_note: 'secret', username: 'alice' },
      { request: { system_admin_note: 'secret', visible: 'keep me' } },
    )
  end
  let(:exception) { StandardError.new("undefined method 'titleize' for nil") }

  before do
    allow(Rails.configuration).to receive(:sentry_dsn).and_return('https://public@example.com/1')
    allow(Rails.application.config).to receive(:after_initialize).and_yield
    allow(Rails.error).to receive(:subscribe)
    allow(rails_config).to receive(:register_error_subscriber=)
    allow(rails_config).to receive(:report_rescued_exceptions=)
    allow(Sentry).to receive(:init).and_yield(config)
    allow(SentryCircuitBreakerService).to receive(:check_within_quota).and_return(true)
  end

  def load_initializer
    load initializer_path
  end

  it 'sanitises event payloads before sending them to Sentry' do
    load_initializer

    expect(rails_config).to have_received(:register_error_subscriber=).with(true)
    expect(rails_config).to have_received(:report_rescued_exceptions=) do |value|
      expect(value).to be(false)
    end
    expect(Rails.error).to have_received(:subscribe) do |subscriber|
      expect(subscriber).to be_a(LoggerErrorSubscriber)
    end

    expect(config.before_send.call(event, { exception: exception })).to eq(
      fake_event_class.new(
        { system_admin_note: '[FILTERED]', visible: 'keep me' },
        { system_admin_note: '[FILTERED]', username: 'alice' },
        { request: { system_admin_note: '[FILTERED]', visible: 'keep me' } },
      )
    )
  end

  it 'fails open when payload sanitisation raises an error' do
    param_filter = instance_double(ActiveSupport::ParameterFilter)
    allow(param_filter).to receive(:filter).with(event.extra).and_return({ password: '[FILTERED]' })
    allow(param_filter).to receive(:filter).with(event.user).and_return({ password: '[FILTERED]' })
    allow(param_filter).to receive(:filter).with(event.contexts).and_raise(NoMethodError, "undefined method 'dig' for Sentry context")
    allow(ActiveSupport::ParameterFilter).to receive(:new).and_return(param_filter)
    allow(Rails.logger).to receive(:warn)

    load_initializer

    expect(config.before_send.call(event, { exception: exception })).to be(event)
    expect(Rails.logger).to have_received(:warn) do |message|
      expect(message).to include('event=sentry_sanitization_error')
      expect(message).to include('original_exception_class=StandardError')
      expect(message).to include("undefined method 'dig' for Sentry context")
    end
  end
end
