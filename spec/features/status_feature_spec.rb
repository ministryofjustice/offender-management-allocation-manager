# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'fetch status' do
  it 'returns a status message' do
    stub_request(:get, 'http://localhost:8000/status').
      to_return(status: 200,
                body: { 'status' => 'ok', 'postgresVersion' => 'PostgreSQL 9.6.4' }.to_json)

    visit '/'

    expect(page).to have_css('.status', text: 'ok')
    expect(page).to have_css('.postgres_version', text: 'PostgreSQL 9.6.4')
  end
end
