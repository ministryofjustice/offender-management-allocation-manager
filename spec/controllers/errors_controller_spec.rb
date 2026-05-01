require 'rails_helper'

RSpec.describe ErrorsController, type: :controller do
  describe '#internal_server_error' do
    let(:exception) { NoMethodError.new("undefined method 'titleize' for nil") }

    before do
      allow(Rails.error).to receive(:report)
    end

    it 'captures the original exception from the Rack env' do
      request.env['action_dispatch.exception'] = exception

      get :internal_server_error

      expect(Rails.error).to have_received(:report).with(
        exception,
        handled: false,
        source: 'exceptions_app'
      )
      expect(response).to have_http_status(:internal_server_error)
    end

    it 'does not capture when there is no original exception in the Rack env' do
      get :internal_server_error

      expect(Rails.error).not_to have_received(:report)
      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
