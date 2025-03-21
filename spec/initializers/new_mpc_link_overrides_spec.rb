# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NewMpcLinkOverrides do
  include Rails.application.routes.url_helpers

  before do
    allow(FeatureFlags).to receive(:new_mpc_links) {
      instance_double(FeatureFlags::EnabledFeature, enabled?: new_mpc_links_enabled)
    }
  end

  describe 'when feature flag is enabled' do
    let(:new_mpc_links_enabled) { true }

    context 'with a link that has been migrated' do
      it 'returns the new MPC host when generating URLs' do
        expect(prison_parole_cases_url('LEI')).to eq('http://localhost:3001/prisons/LEI/parole_cases')
      end

      it 'returns the new MPC host when generating paths' do
        expect(prison_parole_cases_path('LEI')).to eq('http://localhost:3001/prisons/LEI/parole_cases')
      end
    end

    context 'with a link that has not been migrated yet' do
      it 'returns the legacy host when generating urls' do
        expect(prison_poms_url('LEI')).to eq('http://localhost:3000/prisons/LEI/poms')
      end

      it 'returns the path when generating paths' do
        expect(prison_poms_path('LEI')).to eq('/prisons/LEI/poms')
      end
    end
  end

  describe 'when feature flag is disabled' do
    let(:new_mpc_links_enabled) { false }

    context 'with a link that has been migrated' do
      it 'returns the legacy host when generating urls' do
        expect(prison_parole_cases_url('LEI')).to eq('http://localhost:3000/prisons/LEI/parole_cases')
      end

      it 'returns the path when generating paths' do
        expect(prison_parole_cases_path('LEI')).to eq('/prisons/LEI/parole_cases')
      end
    end

    context 'with a link that has not been migrated yet' do
      it 'returns the legacy host when generating urls' do
        expect(prison_poms_url('LEI')).to eq('http://localhost:3000/prisons/LEI/poms')
      end

      it 'returns the path when generating paths' do
        expect(prison_poms_path('LEI')).to eq('/prisons/LEI/poms')
      end
    end
  end
end
