require "rails_helper"

RSpec.describe TierUpdateService do
  subject(:result) { described_class.call(**params) }

  let(:crn) { 'X408769' }
  let(:params) do
    {
      crn:,
      audit_tags:
    }
  end
  let(:audit_tags) { %w[test] }

  describe 'version selection' do
    context 'when new_tiers is enabled' do
      it 'uses version 3' do
        expect(result.version).to eq(3)
      end
    end

    context 'when new_tiers is disabled' do
      before do
        stub_feature_flag(:new_tiers, enabled: false)
      end

      it 'uses version 2' do
        expect(result.version).to eq(2)
      end
    end
  end

  context 'when case info does not exist' do
    it 'returns unchanged' do
      expect(result.status).to eq(:unchanged)
    end
  end

  context 'when case info exists' do
    let!(:case_information) { create(:case_information, crn:, tier: current_tier, manual_entry: true) }
    let(:current_tier) { 'A' }

    context 'when tier API returns nil' do
      before do
        allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3).and_return(nil)
      end

      it 'returns tier_api_failed and does not update the record' do
        expect(result.status).to eq(:tier_api_failed)
        expect(case_information.reload.tier).to eq('A')
      end
    end

    context 'when tier API returns the same tier' do
      before do
        allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
          .and_return({ tier: 'A1', calculation_date: Date.current })
      end

      it 'returns unchanged' do
        expect(result.status).to eq(:unchanged)
      end
    end

    context 'when tier API returns a different tier' do
      before do
        allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
          .and_return({ tier: 'D1', calculation_date: Date.current })
      end

      it 'updates tier and publishes an audit event' do
        expect { result }.to change { AuditEvent.tags('test').count }.by(1)
        expect(result.status).to eq(:updated)
        expect(case_information.reload.tier).to eq('D')
        expect(case_information.reload.manual_entry).to be(false)

        audit_event = AuditEvent.tags('test').last
        expect(audit_event.tags).to include('test', 'case_information', 'tier', 'changed')
      end
    end

    context 'when update is invalid' do
      let(:current_tier) { 'A' }

      before do
        allow(HmppsApi::TieringApi).to receive(:get_tier).with(crn, version: 3)
          .and_return({ tier: 'Z1', calculation_date: Date.current })
      end

      it 'returns update_failed' do
        expect(result.status).to eq(:update_failed)
      end
    end
  end
end
