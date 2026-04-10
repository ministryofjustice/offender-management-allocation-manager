# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RootController, type: :controller do
  describe '#index' do
    before do
      stub_sso_data('RSI', caseloads: %w[LEI RSI])
    end

    it 'clears the cached SSO data and redirects to the current prison dashboard path' do
      get :index

      expect(response).to redirect_to(prison_dashboard_index_path('RSI'))
      expect(session[:sso_data]).to be_nil
    end
  end
end
