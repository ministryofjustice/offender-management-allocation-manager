RSpec.describe DomainEvents::Handlers::ProbationMergeHandler do
  subject(:handler) { described_class.new }

  let(:log_messages) { [] }

  before do
    allow(Shoryuken::Logging.logger).to receive(:info) do |message|
      log_messages << message
    end
  end

  describe 'domain event registration' do
    it 'routes probation merge-related events to the probation merge handler' do
      expect(Rails.configuration.domain_event_handlers).to include(
        'probation-case.merge.completed' => 'DomainEvents::Handlers::ProbationMergeHandler',
        'probation-case.unmerge.completed' => 'DomainEvents::Handlers::ProbationMergeHandler',
      )
    end
  end

  context 'when handling a probation case merge event' do
    let(:event_type) { 'probation-case.merge.completed' }
    let(:event) do
      DomainEvents::Event.new(
        event_type:,
        version: 1,
        description: 'A probation case merge has completed',
        additional_information: {
          'sourceCRN' => 'X12345',
          'targetCRN' => 'X54321',
        },
        external_event: true,
      )
    end

    before do
      allow(CaseInformation).to receive(:exists?).with(crn: 'X12345').and_return(true)
      allow(CaseInformation).to receive(:exists?).with(crn: 'X54321').and_return(false)
    end

    it 'logs start, merge debug and success messages' do
      handler.handle(event)

      aggregate_failures do
        expect(log_messages).to include(
          a_string_matching(
            /event=domain_event_handle_start.*domain_event_type=probation-case\.merge\.completed.*source_crn=X12345.*target_crn=X54321/
          )
        )

        expect(log_messages).to include(
          a_string_matching(
            /\[MERGE\] source case exists\? true - target case exists\? false/
          )
        )

        expect(log_messages).to include(
          a_string_matching(
            /event=domain_event_handle_success.*domain_event_type=probation-case\.merge\.completed.*source_crn=X12345.*target_crn=X54321/
          )
        )

        expect(CaseInformation).to have_received(:exists?).with(crn: 'X12345')
        expect(CaseInformation).to have_received(:exists?).with(crn: 'X54321')
      end
    end
  end

  context 'when handling a probation case unmerge event' do
    let(:event_type) { 'probation-case.unmerge.completed' }
    let(:event) do
      DomainEvents::Event.new(
        event_type:,
        version: 1,
        description: 'A probation case unmerge has completed',
        additional_information: {
          'reactivatedCRN' => 'X12345',
          'unmergedCRN' => 'X54321',
        },
        external_event: true,
      )
    end

    before do
      allow(CaseInformation).to receive(:exists?).with(crn: 'X12345').and_return(false)
      allow(CaseInformation).to receive(:exists?).with(crn: 'X54321').and_return(true)
    end

    it 'logs start, unmerge debug and success messages' do
      handler.handle(event)

      aggregate_failures do
        expect(log_messages).to include(
          a_string_matching(
            /event=domain_event_handle_start.*domain_event_type=probation-case\.unmerge\.completed.*reactivated_crn=X12345.*unmerged_crn=X54321/
          )
        )

        expect(log_messages).to include(
          a_string_matching(
            /\[UNMERGE\] reactivated case exists\? false - unmerged case exists\? true/
          )
        )

        expect(log_messages).to include(
          a_string_matching(
            /event=domain_event_handle_success.*domain_event_type=probation-case\.unmerge\.completed.*reactivated_crn=X12345.*unmerged_crn=X54321/
          )
        )

        expect(CaseInformation).to have_received(:exists?).with(crn: 'X12345')
        expect(CaseInformation).to have_received(:exists?).with(crn: 'X54321')
      end
    end
  end
end
