RSpec.describe DomainEvents::Handlers::PrisonerMergeHandler do
  subject(:handler) { described_class.new }

  let(:log_messages) { [] }

  before do
    allow(Shoryuken::Logging.logger).to receive(:info) do |message|
      log_messages << message
    end

    allow(CaseInformation).to receive(:exists?).with(nomis_offender_id: 'A3645EA').and_return(true)
    allow(CaseInformation).to receive(:exists?).with(nomis_offender_id: 'A3646EA').and_return(false)
  end

  describe 'domain event registration' do
    it 'routes prisoner merge events to the prisoner merge handler' do
      expect(Rails.configuration.domain_event_handlers).to include(
        'prison-offender-events.prisoner.merged' => 'DomainEvents::Handlers::PrisonerMergeHandler',
      )
    end
  end

  it 'logs start, merge debug and success messages' do
    event = DomainEvents::Event.new(
      event_type: 'prison-offender-events.prisoner.merged',
      version: 1,
      description: 'A prisoner has been merged',
      additional_information: {
        'nomsNumber' => 'A3645EA',
        'removedNomsNumber' => 'A3646EA',
      },
      external_event: true,
    )

    handler.handle(event)

    aggregate_failures do
      expect(log_messages).to include(
        a_string_matching(
          /event=domain_event_handle_start.*domain_event_type=prison-offender-events\.prisoner\.merged.*new_offender_id=A3645EA.*old_offender_id=A3646EA/
        )
      )

      expect(log_messages).to include(
        a_string_matching(
          /\[MERGE\] new case exists\? true - old case exists\? false/
        )
      )

      expect(log_messages).to include(
        a_string_matching(
          /event=domain_event_handle_success.*domain_event_type=prison-offender-events\.prisoner\.merged.*new_offender_id=A3645EA.*old_offender_id=A3646EA/
        )
      )

      expect(CaseInformation).to have_received(:exists?).with(nomis_offender_id: 'A3645EA')
      expect(CaseInformation).to have_received(:exists?).with(nomis_offender_id: 'A3646EA')
    end
  end
end
