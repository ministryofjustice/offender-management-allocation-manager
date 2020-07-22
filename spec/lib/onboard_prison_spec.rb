require 'rails_helper'
require 'onboard_prison.rb'

describe OnboardPrison do
  context 'when we initiailize the onboarder' do
    let!(:offender_ids)  { %w[G9468UN G5054VN G1895GH] }
    let!(:delius_records) {
      [
     { noms_no: 'A' },
     { noms_no: 'B' },
     { noms_no: 'G9468UN', tier: 'B', provider_cd: 'NPS' }
        ]
    }

    it 'prepares the offender list by removing existing records' do
      create(:case_information,
             nomis_offender_id: 'G5054VN',
             tier: 'A',
             case_allocation: 'NPS',
             probation_service: 'Wales'
      )
      create(:case_information,
             nomis_offender_id: 'G9468UN',
             tier: 'C',
             case_allocation: 'CRC',
             probation_service: 'Wales'
      )

      op = described_class.new('PVI', offender_ids, nil)
      expect(op.offender_ids.count).to eq(offender_ids.count - 2)
    end

    it 'makes the delius_records faster to search' do
      op = described_class.new('PVI', offender_ids, delius_records)
      expect(op.delius_records).to be_kind_of(Hash)
      expect(op.delius_records.count).to eq(3)
    end

    it 'can complete missing info' do
      op = described_class.new('PVI', offender_ids, delius_records)
      expect {
        op.complete_missing_info
      }.to change(CaseInformation, :count).by(1)
    end
  end
end
