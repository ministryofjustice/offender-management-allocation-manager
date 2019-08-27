require 'rails_helper'

RSpec.describe DeliusDataService, :queueing do
  include ActiveJob::TestHelper

  before do
    test_strategy = Flipflop::FeatureSet.current.test!
    test_strategy.switch!(:auto_delius_import, true)
  end

  describe '#upsert' do
    context 'when there is existing data' do
      let!(:delius_data) {
        DeliusData.create!(
          crn: '1',
          noms_no: 'A1234Z',
          tier: 'A'
        )
      }

      it 'can exercise upsert' do
        expect {
          expect {
            described_class.upsert(
              crn: '1',
              noms_no: 'A1234Z',
              tier: 'B'
            )
          }.not_to change(DeliusData, :count)
        }.to change(enqueued_jobs, :count).by(1)

        expect(delius_data.reload.tier).to eq('B')
      end

      it 'does not queue when there are no changes' do
        expect {
          described_class.upsert(
            crn: '1',
            noms_no: 'A1234Z',
            tier: 'A'
          )
        }.not_to change(enqueued_jobs, :count)
      end

      it 'triggers both old and new when noms_no is updated' do
        expect {
          described_class.upsert(
            crn: '1',
            noms_no: 'G1234Z',
            tier: 'A'
          )
        }.to change(enqueued_jobs, :count).by(2)
      end
    end
  end
end
