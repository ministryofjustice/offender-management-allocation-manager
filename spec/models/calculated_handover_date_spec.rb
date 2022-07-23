RSpec.describe CalculatedHandoverDate do
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
                                            com_allocation_date: com_responsibility.com_allocation_date,
                                            com_responsibility_date: com_responsibility.com_responsibility_date,
                                            reason: com_responsibility.reason))
    end
    let(:com_responsibility) { HandoverDateService::NO_HANDOVER_DATE }
    let(:record) { offender.calculated_handover_date }

    it 'allows nil handover dates' do
      expect(record).to be_valid
      expect(record.com_allocation_date).to be_nil
      expect(record.com_responsibility_date).to be_nil
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

  describe 'using official domain language compliant naming' do
    it 'has #com_allocation_date' do
      subject.com_allocation_date = Date.new(2022, 7, 7)
      expect(subject.com_allocation_date).to eq Date.new(2022, 7, 7)
    end

    it 'has #com_responsibility_date' do
      subject.com_responsibility_date = Date.new(2022, 9, 7)
      expect(subject.com_responsibility_date).to eq Date.new(2022, 9, 7)
    end
  end
end
