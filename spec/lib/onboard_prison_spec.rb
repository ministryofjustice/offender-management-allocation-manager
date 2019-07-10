require 'rails_helper'
require 'onboard_prison.rb'

describe OnboardPrison do
  context 'when we initiailize the onboarder' do
    let!(:offender_ids)  { %w[G9468UN G5054VN G1895GH] }
    let!(:delius_records) {
      [
     { noms_no: 'A' },
     { noms_no: 'B' },
     { noms_no: 'C' }
        ]
    }

    it 'prepares the offender list by removing existing records' do
      CaseInformation.find_or_create_by!(
        nomis_offender_id: 'G5054VN',
        tier: 'A',
        case_allocation: 'NPS',
        omicable: 'Yes'
      )
      CaseInformation.find_or_create_by!(
        nomis_offender_id: 'G9468UN',
        tier: 'C',
        case_allocation: 'CRC',
        omicable: 'Yes'
      )

      op = described_class.new('PVI', offender_ids, nil)
      expect(op.offender_ids.count).to eq(offender_ids.count - 2)
    end

    it 'makes the delius_records faster to search' do
      op = described_class.new('PVI', offender_ids, delius_records)
      expect(op.delius_records).to be_kind_of(Hash)
      expect(op.delius_records.count).to eq(3)
    end
  end
end
