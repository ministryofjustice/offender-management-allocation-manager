RSpec.describe DomainEvents::Handlers::TierChangeHandler do
  subject!(:handler) { described_class.new }

  before do
    stub_const('ENABLE_EVENT_BASED_PROBATION_CHANGE', true)
    allow(Shoryuken::Logging.logger).to receive(:info).and_return(nil)
    allow(Shoryuken::Logging.logger).to receive(:error).and_return(nil)
    allow(HmppsApi::TieringApi).to receive(:get_calculation).and_return({ tier: tier_from_api })
  end

  let(:event) do
    DomainEvents::Event.new(
      event_type: 'tier.calculation.complete',
      version: 1,
      description: 'A fabulous description',
      detail_url: 'https://example.org/irrelevant',
      additional_information: { 'calculationId' => 'bishboshbash' },
      crn_number: crn,
      external_event: true
    )
  end

  let(:crn) { 'X08769' }
  let(:tier_from_api) { 'D1' }

  context 'when local case information found' do
    let!(:case_information) do
      create(:case_information, crn: crn)
    end

    before { handler.handle(event) }

    context 'when case information update successful' do
      it 'updates tier with first char of new value' do
        expect(case_information.reload.tier).to eq('D')
      end

      it 'emits a log info message' do
        expect(Shoryuken::Logging.logger).to have_received(:info).at_least(2).times
      end
    end

    context 'when case information update not successful' do
      let(:tier_from_api) { 'Z1' }

      it 'emits a log error message' do
        expect(Shoryuken::Logging.logger).to have_received(:error).once
      end
    end
  end

  context 'when local case information not found' do
    before { handler.handle(event) }

    it 'emits a log error message' do
      expect(Shoryuken::Logging.logger).to have_received(:error).once
    end
  end
end
