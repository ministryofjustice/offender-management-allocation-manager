require "rails_helper"

describe Offender::Parole do
  describe '#target_hearing_date' do
    it 'returns the target hearing date of the most recent completed parole review' do
      offender = create(:offender)
      create(:parole_review, :active, nomis_offender_id: offender.nomis_offender_id, target_hearing_date: Date.parse('25/12/2023'))
      create(:parole_review, :complete, nomis_offender_id: offender.nomis_offender_id, target_hearing_date: Date.parse('01/01/2024'))
      create(:parole_review, :complete, nomis_offender_id: offender.nomis_offender_id, target_hearing_date: Date.parse('25/12/2024'))
      expect(offender.target_hearing_date).to eq(Date.parse('25/12/2024'))
    end
  end
end
