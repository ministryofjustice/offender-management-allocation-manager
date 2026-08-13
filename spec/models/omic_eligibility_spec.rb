# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OmicEligibility do
  describe '.eligible' do
    let!(:eligible_record) { create(:omic_eligibility, nomis_offender_id: 'G1234AB', eligible: true) }
    let!(:ineligible_record) { create(:omic_eligibility, nomis_offender_id: 'G1234AC', eligible: false) }

    it 'returns only eligible offenders' do
      expect(described_class.eligible).to contain_exactly(eligible_record)
      expect(described_class.eligible).not_to include(ineligible_record)
    end
  end

  describe '.stale' do
    let!(:stale_record) { create(:omic_eligibility, nomis_offender_id: 'G1234AD', eligible: false, missing_runs_count: 1) }
    let!(:fresh_record) { create(:omic_eligibility, nomis_offender_id: 'G1234AE', eligible: false, missing_runs_count: 0) }

    it 'returns only offenders with missing_runs_count greater than zero' do
      expect(described_class.stale).to contain_exactly(stale_record)
      expect(described_class.stale).not_to include(fresh_record)
    end
  end
end
