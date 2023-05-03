RSpec.describe Api::Handover do
  subject(:handover) { described_class[nomis_offender_id] }

  let(:nomis_offender_id) { 'X1111XX' }
  let(:db_handover_model) do
    instance_double(CalculatedHandoverDate,
                    nomis_offender_id: nomis_offender_id,
                    handover_date: Date.new(2021, 2, 1),
                    start_date: Date.new(2021, 2, 1),
                    responsibility: CalculatedHandoverDate::CUSTODY_ONLY)
  end

  before do
    allow(CalculatedHandoverDate).to receive(:find_by_nomis_offender_id).and_return(nil)
    allow(CalculatedHandoverDate).to receive(:find_by_nomis_offender_id).with(nomis_offender_id)
                                                                        .and_return(db_handover_model)
  end

  describe 'with a valid handover DB model' do
    it 'has valid API fields' do
      aggregate_failures do
        expect(handover.noms_number).to eq nomis_offender_id
        expect(handover.handover_date).to eq Date.new(2021, 2, 1)
      end
    end

    it 'when POM responsible is the right value' do
      expect(handover.responsibility).to eq 'POM'
    end

    it 'when COM responsible is the right value' do
      allow(db_handover_model).to receive_messages(responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE)
      expect(handover.responsibility).to eq 'COM'
    end

    describe 'when no handover window' do
      it 'has no handover start date' do
        expect(handover.handover_start_date).to eq nil
      end

      it 'serialises to JSON' do
        expect(handover.as_json).to eq({
          'nomsNumber' => nomis_offender_id,
          'handoverDate' => '2021-02-01',
          'responsibility' => 'POM',
        })
      end
    end

    describe 'when there is a handover window' do
      before do
        allow(db_handover_model).to receive_messages(start_date: Date.new(2021, 1, 1))
      end

      it 'has an earlier handover start date' do
        expect(handover.handover_start_date).to eq Date.new(2021, 1, 1)
      end

      it 'is POM responsible if in the handover window' do
        allow(db_handover_model).to receive_messages(responsibility: CalculatedHandoverDate::CUSTODY_WITH_COM)
        expect(handover.responsibility).to eq 'POM'
      end

      it 'serialises to JSON' do
        expect(handover.as_json).to eq({
          'nomsNumber' => nomis_offender_id,
          'handoverDate' => '2021-02-01',
          'handoverStartDate' => '2021-01-01',
          'responsibility' => 'POM',
        })
      end
    end
  end

  describe 'when the DB model has no handover date' do
    before do
      allow(db_handover_model).to receive_messages(handover_date: nil)
    end

    it 'the constructor returns nil' do
      expect(handover).to eq nil
    end
  end

  describe 'when the DB model has no responsibility' do
    before do
      allow(db_handover_model).to receive_messages(responsibility: nil)
    end

    it 'the constructor returns nil' do
      expect(handover).to eq nil
    end
  end

  describe 'when the DB model does not exist' do
    subject(:handover) { described_class['X2222XX'] }

    it 'the constructor returns nil' do
      expect(handover).to eq nil
    end
  end
end
