RSpec.describe CalculatedHandoverDate, :disable_push_to_delius do
  subject { build(:calculated_handover_date) }

  let(:today) { Time.zone.today }
  let(:offender) { FactoryBot.create(:offender, nomis_offender_id: 'X1111XX') }

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
            nomis_offender_id: "A1234BC")
    end

    it 'is not valid' do
      expect(subject.valid?).to be(false)
    end
  end

  describe '::by_upcoming_handover scope' do
    let(:upcoming_handover_date_attributes) do
      {
        handover_date: Date.new(2022, 12, 1),
      }
    end
    let!(:row) do
      # instantiate it immediately
      FactoryBot.create :calculated_handover_date, :before_handover, offender: offender,
                                                                     **upcoming_handover_date_attributes
    end

    def query(offender_ids: [offender.id], relative_to_date: Date.new(2022, 11, 21))
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
    let!(:row) do
      # instantiate it immediately
      FactoryBot.create :calculated_handover_date, :after_handover, offender: offender
    end

    def query(offender_ids: [offender.id])
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

  describe '::by_com_allocation_overdue' do
    subject!(:row) do
      # instantiate it immediately
      FactoryBot.create :calculated_handover_date, :after_handover, offender: offender
    end

    let!(:case_information) { FactoryBot.create :case_information, :english, offender: offender }

    def query(offender_ids: [offender.id])
      described_class.by_com_allocation_overdue(offender_ids: offender_ids, relative_to_date: Date.new(2022, 11, 21))
    end

    describe 'when 48 hours after handover date' do
      before do
        row.update! responsibility: described_class::COMMUNITY_RESPONSIBLE, handover_date: Date.new(2022, 11, 19)
      end

      describe 'when neither COM email or COM name of test subject is allocated' do
        before do
          case_information.update! com_name: nil, com_email: nil
        end

        it 'finds the test subject if their offender ID is in `offender_ids`' do
          expect(query).to include row
        end

        it 'does not find the test subject if its offener ID is not listed in `offender_ids`' do
          expect(query(offender_ids: ['Y1111YY'])).not_to include row
        end

        it 'does not get the case when not community responsible' do
          row.update! responsibility: described_class::CUSTODY_ONLY
          expect(query).not_to include row
        end
      end

      it 'does not find rows who have a COM email but not a COM name' do
        case_information.update! com_email: 'a@b', com_name: nil
        expect(query).not_to include row
      end

      it 'does not find rows who do not have COM email but do have a COM_name' do
        case_information.update! com_email: nil, com_name: 'A B'
        expect(query).not_to include row
      end
    end

    describe 'when less than 48 hours after handover date' do
      before do
        row.update! responsibility: described_class::COMMUNITY_RESPONSIBLE, handover_date: Date.new(2022, 11, 20)
      end

      it 'does not get cases without COM allocated' do
        case_information.update! com_email: nil
        expect(query).not_to include(row)
      end
    end
  end
end
