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
                                            com_allocated_date: com_responsibility.com_allocated_date,
                                            com_responsible_date: com_responsibility.com_responsible_date,
                                            reason: com_responsibility.reason))
    end
    let(:com_responsibility) { HandoverDateService::NO_HANDOVER_DATE }
    let(:record) { offender.calculated_handover_date }

    it 'allows nil handover dates' do
      expect(record).to be_valid
      expect(record.com_allocated_date).to be_nil
      expect(record.com_responsible_date).to be_nil
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
    it 'has #com_allocated_date' do
      subject.com_allocated_date = Date.new(2022, 7, 7)
      expect(subject.com_allocated_date).to eq Date.new(2022, 7, 7)
    end

    it 'has #com_responsible_date' do
      subject.com_responsible_date = Date.new(2022, 9, 7)
      expect(subject.com_responsible_date).to eq Date.new(2022, 9, 7)
    end
  end

  describe '::by_upcoming_handover scope' do
    let(:upcoming_handover_date_attributes) do
      {
        handover_date: Date.new(2022, 12, 1),
      }
    end
    let!(:row) do # instantiate it immediately
      FactoryBot.create :calculated_handover_date, :before_handover,
                        offender: FactoryBot.create(:offender, nomis_offender_id: 'X1111XX'),
                        **upcoming_handover_date_attributes
    end

    def query(offender_ids: ['X1111XX'], relative_to_date: Date.new(2022, 11, 21))
      described_class.by_upcoming_handover(offender_ids: offender_ids,
                                           relative_to_date: relative_to_date,
                                           upcoming_handover_window_duration: 10)
    end

    it 'gets the rows matching given criteria' do
      expect(query).to include row
    end

    it 'does not get rows for unwanted offenders' do
      row.update! offender: FactoryBot.create(:offender, nomis_offender_id: 'X2222XX')
      expect(query).not_to include row
    end

    it 'does not get rows unless cases are pom-responsible' do
      row.update! responsibility: described_class::COMMUNITY_RESPONSIBLE
      expect(query).not_to include row
    end

    it 'gets rows within the upcoming handover window' do
      aggregate_failures do
        expect(query(relative_to_date: Date.new(2022, 11, 21))).to include row
        expect(query(relative_to_date: Date.new(2022, 11, 30))).to include row
      end
    end

    it 'does not get rows where upcoming handover window not yet reached' do
      expect(query(relative_to_date: Date.new(2022, 11, 20))).not_to include row
    end

    it 'does not get rows where com allocated date is reached' do
      expect(query(relative_to_date: Date.new(2022, 12, 1))).not_to include row
    end

    it 'does not get rows where com allocated date is passed' do
      expect(query(relative_to_date: Date.new(2022, 12, 2))).not_to include row
    end

    it 'does not get rows where com responsible date is reached' do
      expect(query(relative_to_date: Date.new(2022, 12, 30))).not_to include row
    end

    it 'does not get rows where com responsible date is past' do
      expect(query(relative_to_date: Date.new(2022, 12, 31))).not_to include row
    end
  end

  describe '::by_handover_in_progress scope' do
    let!(:row) do # instantiate it immediately
      FactoryBot.create :calculated_handover_date, :after_handover,
                        offender: FactoryBot.create(:offender, nomis_offender_id: 'X1111XX')
    end

    def query(offender_ids: ['X1111XX'])
      described_class.by_handover_in_progress(offender_ids: offender_ids)
    end

    it 'gets the rows that are POM responsible with COM supporting for the given list of offenders' do
      expect(query).to include row
    end

    it 'does not get rows for unwanted offenders' do
      row.update! offender: FactoryBot.create(:offender, nomis_offender_id: 'X2222XX')
      expect(query).not_to include row
    end

    it 'gets all rows that are COM-responsible' do
      row.update! responsibility: described_class::COMMUNITY_RESPONSIBLE
      expect(query).to include row
    end

    it 'does not include rows where COM is not assigned' do
      row.update! responsibility: described_class::CUSTODY_ONLY
      expect(query).not_to include row
    end

    it 'does not include rows that have no handover date' do
      FactoryBot.create :calculated_handover_date,
                        responsibility: described_class::COMMUNITY_RESPONSIBLE,
                        handover_date: nil,
                        start_date: nil,
                        offender: FactoryBot.create(:offender, nomis_offender_id: 'X2222XX')

      expect(query(offender_ids: ['X2222XX'])).to be_blank
    end
  end
end
