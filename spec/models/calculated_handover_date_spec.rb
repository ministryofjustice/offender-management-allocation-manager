require 'rails_helper'

RSpec.describe CalculatedHandoverDate, type: :model do
  subject { build(:calculated_handover_date) }

  let(:today) { Time.zone.today }

  before do
    allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)
  end

  describe 'validation' do
    it { is_expected.to validate_uniqueness_of(:nomis_offender_id) }
  end

  it { is_expected.to belong_to(:offender) }

  context 'with nil handover dates' do
    let(:offender) do
      build(:offender,
            calculated_handover_date: build(:calculated_handover_date,
                                            responsibility: com_responsibility.responsibility,
                                            start_date: com_responsibility.start_date,
                                            handover_date: com_responsibility.handover_date,
                                            reason: com_responsibility.reason))
    end
    let(:com_responsibility) { HandoverDateService::NO_HANDOVER_DATE }
    let(:record) { offender.calculated_handover_date }

    it 'allows nil handover dates' do
      expect(record).to be_valid
      expect(record.start_date).to be_nil
      expect(record.handover_date).to be_nil
      expect(record.reason_text).to eq('COM Responsibility')
    end
  end

  describe "when nomis_offender_id is set but an associated case information record doesn't exist" do
    subject do
      build(:calculated_handover_date,
            offender: nil,
            nomis_offender_id: "A1234BC"
           )
    end

    it 'is not valid' do
      expect(subject.valid?).to be(false)
    end
  end
end
