require 'rails_helper'

# All these specs run the same job, so they can all share a VCR cassette
RSpec.describe ProcessDeliusDataJob, vcr: { cassette_name: :process_delius_job_switch }, type: :job do
  let(:nomis_offender_id) { 'G4281GV' }

  context 'with one prison enabled' do
    before do
      ENV['AUTO_DELIUS_IMPORT'] = 'VEN,LEI,HGT'
    end

    context 'when on the happy path' do
      let!(:d1) { create(:delius_data) }

      it 'creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.to change(CaseInformation, :count).by(1)
      end
    end
  end

  context 'with non-enabled prison' do
    before do
      ENV['AUTO_DELIUS_IMPORT'] = 'RSI,VEN'
    end

    context 'when on the happy path' do
      let!(:d1) { create(:delius_data) }

      it 'creates case information' do
        expect {
          described_class.perform_now d1.noms_no
        }.not_to change(CaseInformation, :count)
      end
    end
  end
end
