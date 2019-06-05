require 'rails_helper'
require 'onboard_prison.rb'

describe OnboardPrison do
  context  'can de;termine which offenders need a CaseInformation record' do
    let!(:offender_ids)  { [ 'G9468UN', 'G5054VN', 'G1895GH' ] }

    it 'returns a list of offenders that are missing two records' do
      CaseInformation.find_or_create_by!(
          nomis_offender_id: 'G5054VN',
          tier: 'A',
          case_allocation: 'NPS',
          omicable: 'Yes',
          prison: 'PVI'
      )
      CaseInformation.find_or_create_by!(
          nomis_offender_id: 'G9468UN',
          tier: 'C',
          case_allocation: 'CRC',
          omicable: 'Yes',
          prison: 'PVI'
      )

      op = described_class.new(offender_ids, nil)
      expect(op.offender_ids.count).to eq(offender_ids.count - 2)
    end
  end
end