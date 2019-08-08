require 'rails_helper'

RSpec.describe ProcessDeliusDataJob, vcr: { cassette_name: :process_delius_job }, type: :job do
  let(:nomis_offender_id) { 'G4281GV' }
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }

  before do
    test_strategy.switch!(:auto_delius_import, true)
  end

  after do
    test_strategy.switch!(:auto_delius_import, false)
  end

  context 'when duplicate NOMIS ids exist' do
    let!(:d1) { create(:delius_data, noms_no: nomis_offender_id) }
    let!(:d2) { create(:delius_data, noms_no: nomis_offender_id) }

    it 'flags up the duplicate CRNS' do
      expect {
        expect {
          described_class.perform_now nomis_offender_id
        }.not_to change(CaseInformation, :count)
      }.to change(DeliusImportError, :count).by(1)

      expect(DeliusImportError.last(2).map(&:nomis_offender_id)).to match_array [nomis_offender_id]
      expect(DeliusImportError.last(2).map(&:error_type)).to match_array [DeliusImportError::DUPLICATE_NOMIS_ID]
    end
  end

  context 'when on the happy path' do
    let!(:d1) { create(:delius_data) }

    it 'creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.to change(CaseInformation, :count).by(1)
    end
  end

  context 'when tier contains extra characters' do
    let!(:d1) { create(:delius_data, tier: 'B1') }

    it 'creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.to change(CaseInformation, :count).by(1)
    end
  end

  context 'when tier contains extra characters' do
    let!(:d1) { create(:delius_data, tier: 'B1') }

    it 'creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.to change(CaseInformation, :count).by(1)
      expect(CaseInformation.last.tier).to eq('B')
    end
  end

  context 'when tier is invalid' do
    let!(:d1) { create(:delius_data, tier: 'X') }

    it 'does not creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.not_to change(CaseInformation, :count)
    end
  end

  describe '#mappa' do
    context 'without delius mappa' do
      let!(:d1) { create(:delius_data, mappa: 'N') }

      it 'creates case information with mappa level 0' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(1)
        expect(CaseInformation.last.mappa_level).to eq(0)
      end
    end

    context 'with delius mappa' do
      let!(:d1) { create(:delius_data, mappa: 'Y', mappa_levels: mappa_levels) }

      context 'with delius mappa data is 1' do
        let(:mappa_levels) { '1' }

        it 'creates case information with mappa level 1' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
          expect(CaseInformation.last.mappa_level).to eq(1)
        end
      end

      context 'with delius mappa data is 1,2' do
        let(:mappa_levels) { '1,2' }

        it 'creates case information with mappa level 2' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
          expect(CaseInformation.last.mappa_level).to eq(2)
        end
      end

      context 'with delius mappa data is 1,Nominal' do
        let(:mappa_levels) { '1,Nominal' }

        it 'creates case information with mappa level 1' do
          expect {
            described_class.perform_now d1.noms_no
          }.to change(CaseInformation, :count).by(1)
          expect(CaseInformation.last.mappa_level).to eq(1)
        end
      end
    end
  end

  context 'when tier is missing' do
    let!(:d1) { create(:delius_data, tier: nil) }

    it 'does not creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.not_to change(CaseInformation, :count)
    end
  end

  context 'when invalid service provider' do
    let!(:d1) { create(:delius_data, provider_code: 'X123') }

    it 'does not creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.not_to change(CaseInformation, :count)
    end
  end

  context 'when date invalid' do
    let!(:d1) { create(:delius_data, date_of_birth: '******') }

    it 'creates an error record' do
      expect {
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
      }.to change(DeliusImportError, :count).by(1)
    end
    # expect(DeliusImportError.last.error_type).to eq(DeliusImportError::MISMATCHED_DOB)
  end

  context 'when case information already present' do
    let!(:d1) { create(:delius_data, tier: 'C') }
    let!(:c1) { create(:case_information, tier: 'B', nomis_offender_id: d1.noms_no, crn: d1.crn) }

    it 'does not creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.not_to change(CaseInformation, :count)
      expect(c1.reload.tier).to eq('C')
    end
  end

  context 'when case information already present' do
    let!(:c1) { create(:case_information, tier: 'B', nomis_offender_id: 'G4281GV') }
    let!(:d1) { create(:delius_data, noms_no: c1.nomis_offender_id, crn: c1.crn, tier: 'C') }

    it 'does not creates case information' do
      expect {
        described_class.perform_now d1.noms_no
      }.not_to change(CaseInformation, :count)
      expect(c1.reload.tier).to eq('C')
    end
  end
end
