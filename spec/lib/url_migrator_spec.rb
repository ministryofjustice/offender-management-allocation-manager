# frozen_string_literal: true

require 'rails_helper'

describe UrlMigrator do
  let(:new_mpc_links_enabled) { true }

  before do
    allow(Rails.configuration).to receive(:allocation_manager_host).and_return('http://legacy-mpc-host')
    allow(Rails.configuration).to receive(:new_mpc_host).and_return('http://new-mpc-host')

    allow(FeatureFlags).to receive(:new_mpc_links) {
      instance_double(FeatureFlags::EnabledFeature, enabled?: new_mpc_links_enabled)
    }

    described_class.reset!
  end

  describe 'rails named links' do
    it 'raises method not found error for a non-existent method' do
      expect { described_class.non_existent_method }.to raise_error(NoMethodError)
    end

    context 'when `new_mpc_links` feature flag is enabled' do
      it 'returns the new MPC host when generating URLs' do
        expect(described_class.prison_parole_cases_url('LEI')).to eq('http://new-mpc-host/prisons/LEI/parole_cases')
      end

      it 'returns the new MPC host when generating paths' do
        expect(described_class.prison_parole_cases_path('LEI')).to eq('http://new-mpc-host/prisons/LEI/parole_cases')
      end
    end

    context 'when `new_mpc_links` feature flag is disabled' do
      let(:new_mpc_links_enabled) { false }

      it 'returns the legacy host' do
        expect(described_class.prison_parole_cases_url('LEI')).to eq('http://legacy-mpc-host/prisons/LEI/parole_cases')
      end

      it 'returns the path when generating paths' do
        expect(described_class.prison_parole_cases_path('LEI')).to eq('/prisons/LEI/parole_cases')
      end
    end
  end
end
