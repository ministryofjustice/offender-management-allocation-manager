require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    def index
      raise 'request failed' if params[:fail]

      head :ok
    end
  end

  it 'includes request correlation in structured logs on success and failure' do
    allow_any_instance_of(ActionDispatch::Request).to receive(:request_id).and_return('request-id')
    payloads = []
    subscriber = ActiveSupport::Notifications.subscribe('process_action.action_controller') { |event| payloads << event.payload }
    begin
      get :index
      expect { get :index, params: { fail: true } }.to raise_error(RuntimeError, 'request failed')
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    options = payloads.map { Rails.application.config.lograge.custom_options.call(double(payload: it)) }
    expect(options).to all(include(request_id: 'request-id'))
    expect(options.last).to include(exception: ['RuntimeError', 'request failed'], backtrace: an_instance_of(Array))
  end
end
