# frozen_string_literal: true

RSpec.describe DeliusDataImportService do
  subject(:service) { described_class.new }

  let(:nomis_offender_id) { 'G4281GV' }
  let(:crn) { 'X362207' }
  let(:ldu) { create(:local_delivery_unit) }
  let(:prison) { create(:prison) }
  let(:case_info) { CaseInformation.last }
  let(:team_name) { Faker::Company.name }
  let(:com_forename) { 'Arnold' }
  let(:com_surname) { 'Aardvark' }
  let(:com_email) { 'arnie@aardvark.me' }
  let(:resourcing) { 'ENHANCED' }
  let(:tier) { 'A_2' }
  let(:rosh_level) { 'HIGH' }
  let(:rosh_start_date) { Date.new(2026, 3, 14) }

  let(:mock_probation_record) do
    build :probation_record, offender_no: nomis_offender_id,
                             crn: crn,
                             tier: tier,
                             resourcing: resourcing,
                             team_description: team_name,
                             ldu_code: ldu.code,
                             ldu_description: ldu.name,
                             rosh_level: rosh_level,
                             rosh_start_date: rosh_start_date,
                             com_forename: com_forename,
                             com_surname: com_surname,
                             com_email: com_email
  end

  let(:new_case_information_attributes) do
    {
      enhanced_resourcing: true,
      crn: "X362207",
      manual_entry: false,
      mappa_level: 0,
      nomis_offender_id: nomis_offender_id,
      probation_service: "England",
      local_delivery_unit_id: ldu.id,
      ldu_code: ldu.code,
      team_name: team_name,
      com_name: "#{com_surname}, #{com_forename}",
      com_email: com_email,
      tier: "A",
      rosh_level: rosh_level,
      rosh_start_date: rosh_start_date,
    }
  end

  let(:audit_case_information_attributes) do
    new_case_information_attributes.merge(rosh_start_date: rosh_start_date&.to_s).stringify_keys
  end

  before do
    allow(OffenderService).to receive(:get_probation_record).with(nomis_offender_id)
      .and_return(mock_probation_record)
  end

  shared_examples 'audit event' do
    let(:audit_event) { AuditEvent.last }

    it 'creates an audit event with the expected data and tags' do
      expect {
        service.process(nomis_offender_id)
      }.to change(AuditEvent, :count).by(1)

      expect(audit_event.data['before']).to eq(expected_data['before'])
      expect(audit_event.data['after']).to eq(expected_data['after'])
      expect(audit_event.tags).to include('batch')
    end
  end

  context 'when case_information not present' do
    it 'creates case information' do
      expect {
        service.process(nomis_offender_id)
      }.to change(CaseInformation, :count).by(1)

      expect(
        case_info.attributes.symbolize_keys.except(
          :created_at, :id, :updated_at, :target_hearing_date, :prisoner_id, :welsh_offender, :active_vlo
        )
      ).to eq(new_case_information_attributes)
    end

    include_examples 'audit event' do
      let(:expected_data) do
        {
          'before' => {
            'crn' => nil,
            'tier' => nil,
            'com_name' => nil,
            'ldu_code' => nil,
            'com_email' => nil,
            'team_name' => nil,
            'mappa_level' => nil,
            'manual_entry' => nil,
            'nomis_offender_id' => nil,
            'probation_service' => nil,
            'enhanced_resourcing' => nil,
            'local_delivery_unit_id' => nil,
            'rosh_level' => nil,
            'rosh_start_date' => nil
          },
          'after' => audit_case_information_attributes
        }
      end
    end
  end

  context 'when rosh details are missing' do
    let(:rosh_level) { nil }
    let(:rosh_start_date) { nil }

    it 'stores nil rosh values' do
      service.process(nomis_offender_id)

      expect(case_info.reload.rosh_level).to be_nil
      expect(case_info.rosh_start_date).to be_nil
    end
  end

  context 'when processing a com name' do
    let(:offender_id) { 'A1111AA' }
    let(:nomis_offender_id) { offender_id }

    context 'with no COM details' do
      let(:mock_probation_record) do
        build :probation_record, :no_com, offender_no: nomis_offender_id,
                                          crn: crn,
                                          tier: tier,
                                          team_description: team_name,
                                          ldu_code: ldu.code,
                                          ldu_description: ldu.name
      end

      let(:com_name) { 'Staff, Unallocated' }
      let(:unallocated) { true }

      it 'maps com_name to nil' do
        expect {
          service.process(offender_id)
        }.to change(CaseInformation, :count).by(1)

        expect(case_info.com_name).to be_nil
      end
    end
  end

  context 'when tier contains extra characters' do
    let(:tier) { 'B1' }

    it 'creates case information' do
      expect {
        service.process(nomis_offender_id)
      }.to change(CaseInformation, :count).by(1)
      expect(case_info.tier).to eq('B')
    end
  end

  context 'when tier is invalid' do
    let(:tier) { 'X' }

    it 'does not create case information' do
      expect {
        service.process(nomis_offender_id)
      }.not_to change(CaseInformation, :count)
    end
  end

  context 'when rosh level is invalid' do
    let(:rosh_level) { 'UNKNOWN' }

    it 'does not create case information and stores a rosh import error' do
      expect {
        service.process(nomis_offender_id)
      }.not_to change(CaseInformation, :count)

      expect(DeliusImportError.where(nomis_offender_id: nomis_offender_id).pluck(:error_type))
        .to eq([DeliusImportError::INVALID_ROSH_LEVEL])
    end
  end

  describe '#probation_service' do
    context 'with a Welsh LDU' do
      let(:ldu) { create(:local_delivery_unit, country: 'Wales') }

      it 'maps to Wales' do
        service.process(nomis_offender_id)
        expect(case_info.probation_service).to eq('Wales')
      end
    end
  end

  describe 'Local Delivery Unit' do
    context 'when the LDU code is not in our lookup table' do
      let(:ldu) { OpenStruct.new(code: 'ABC123', name: 'Captain Underpants') }

      before do
        service.process(nomis_offender_id)
      end

      it 'imports the record, but without an LDU association' do
        expect(case_info.local_delivery_unit).to be_nil
      end

      it 'records the LDU code' do
        expect(case_info.ldu_code).to eq ldu.code
      end
    end
  end

  context 'when case information already present' do
    let!(:c1) { create(:case_information, :manual_entry, tier: 'B', offender: build(:offender, nomis_offender_id: nomis_offender_id)) }
    let(:tier) { 'C' }

    it 'does not create case information' do
      expect {
        service.process(nomis_offender_id)
      }.not_to change(CaseInformation, :count)
    end

    it 'does not update tier' do
      service.process(nomis_offender_id)

      expect(c1.reload.tier).to eq('B')
    end

    it 'updates other attributes' do
      service.process(nomis_offender_id)

      expect(c1.reload.team_name).to eq(team_name)
      expect(c1.reload.com_email).to eq(com_email)
      expect(c1.reload.local_delivery_unit).to eq(ldu)
    end

    include_examples 'audit event' do
      let(:attrs_not_changing) { %w[id created_at updated_at active_vlo nomis_offender_id tier rosh_level] }
      let(:expected_data) do
        {
          'before' => c1.attributes.except(*attrs_not_changing).merge('rosh_start_date' => c1.rosh_start_date&.to_s),
          'after' => audit_case_information_attributes.except('nomis_offender_id', 'tier', 'rosh_level')
        }
      end
    end

    context 'when the existing rosh level is already present' do
      let!(:c1) do
        create(:case_information, :manual_entry,
               offender: build(:offender, nomis_offender_id: nomis_offender_id),
               tier: 'B',
               rosh_level: 'LOW')
      end

      context 'when probation rosh is nil' do
        let(:rosh_level) { nil }

        it 'preserves the existing rosh level' do
          service.process(nomis_offender_id)

          expect(c1.reload.rosh_level).to eq('LOW')
        end
      end

      context 'when probation rosh is present' do
        let(:rosh_level) { 'HIGH' }

        it 'overwrites the existing rosh level' do
          service.process(nomis_offender_id)

          expect(c1.reload.rosh_level).to eq('HIGH')
        end
      end
    end

    context 'when probation resourcing is missing' do
      let(:resourcing) { nil }

      it 'preserves the existing enhanced resourcing value if any' do
        c1.update!(enhanced_resourcing: false)

        service.process(nomis_offender_id)

        expect(c1.reload.enhanced_resourcing).to be(false)
      end
    end

    context 'when probation resourcing is present' do
      let(:resourcing) { 'STANDARD' }

      it 'overwrites the existing enhanced resourcing value' do
        c1.update!(enhanced_resourcing: true)

        service.process(nomis_offender_id)

        expect(c1.reload.enhanced_resourcing).to be(false)
      end
    end
  end

  context 'when using CRN as the identifier' do
    let(:service) { described_class.new(identifier_type: :crn) }

    before do
      allow(OffenderService).to receive(:get_probation_record).with(crn).and_return(mock_probation_record)
      allow(service.logger).to receive(:error)
      service.process(crn)
    end

    context 'when the probation record does not have a NOMIS offender ID' do
      let(:nomis_offender_id) { nil }

      it 'logs an error' do
        expect(service.logger).to have_received(:error).once
      end
    end
  end

  context 'with error handling' do
    context 'with non-retriable client errors' do
      [
        Faraday::ResourceNotFound,
        Faraday::BadRequestError,
        Faraday::ForbiddenError,
        Faraday::ConflictError,
        Faraday::UnprocessableEntityError,
      ].each do |error_class|
        it "handles #{error_class} as non-retriable" do
          allow(OffenderService).to receive(:get_probation_record).and_raise(error_class, 'client error')
          allow(service.logger).to receive(:warn)

          expect { service.process(nomis_offender_id) }.not_to raise_error
          expect(service.logger).to have_received(:warn).with(/event=client_error/)
          expect(service.errors).to be_empty
        end
      end
    end

    context 'with retriable errors' do
      it 'handles Faraday::UnauthorizedError as retriable' do
        allow(OffenderService).to receive(:get_probation_record).and_raise(Faraday::UnauthorizedError, 'unauthorized')
        allow(service.logger).to receive(:warn)

        expect { service.process(nomis_offender_id) }.not_to raise_error
        expect(service.logger).to have_received(:warn).with(/event=unauthorized/)
        expect(service.errors).to eq(nomis_offender_id => 'unauthorized')
      end

      {
        Faraday::ServerError => 'internal server error',
        Faraday::TimeoutError => 'request timed out',
        Faraday::ConnectionFailed => 'connection refused',
        StandardError => 'something went wrong',
      }.each do |error_class, message|
        it "tracks #{error_class}" do
          allow(OffenderService).to receive(:get_probation_record).and_raise(error_class, message)
          allow(service.logger).to receive(:warn)

          expect { service.process(nomis_offender_id) }.not_to raise_error
          expect(service.logger).to have_received(:warn).with(/event=exception/)
          expect(service.errors).to eq(nomis_offender_id => message)
        end
      end
    end

    it 'does not track identifiers that succeed' do
      service.process(nomis_offender_id)

      expect(service.errors).to be_empty
    end
  end
end
