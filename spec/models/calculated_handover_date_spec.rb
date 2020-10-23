require 'rails_helper'

RSpec.describe CalculatedHandoverDate, type: :model do
  subject { build(:calculated_handover_date) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_uniqueness_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:reason) }
  end

  it { is_expected.to belong_to(:case_information) }

  it 'allows nil handover dates' do
    case_info = create(:case_information)
    com_responsibility = HandoverDateService::NO_HANDOVER_DATE

    record = described_class.create!(
      nomis_offender_id: case_info.nomis_offender_id,
      start_date: com_responsibility.start_date,
      handover_date: com_responsibility.handover_date,
      reason: com_responsibility.reason
    )

    record.reload
    expect(record.start_date).to be_nil
    expect(record.handover_date).to be_nil
    expect(record.reason).to eq('COM Responsibility')
  end

  describe "when nomis_offender_id is set but an associated case information record doesn't exist" do
    subject {
      build(:calculated_handover_date,
            case_information: nil,
            nomis_offender_id: "A1234BC"
      )
    }

    it 'is not valid' do
      expect(subject.valid?).to be(false)
      expect(subject.save).to be(false)
    end
  end
end
