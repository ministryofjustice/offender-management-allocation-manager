# frozen_string_literal: true

# NOTES for future developers
#
# This test is a clusterduck. It tries to be a full integration test, and then ends up having to mock the lowest level
# of the stack - the API calls made at the networking library.
#
# With the introduction of the new COM details API call, this test is moving to a unit test. So OffenderService is
# stubbed to return a mocked value and we do not need to worry about what API calls it is making or how it is processing
# the data.
#
# Please follow this pattern for all future work - when significant work is done on any behaviour, that behaviour's test
# section should replace API mocks with dependency mocks as has been described above.
RSpec.describe ProcessDeliusDataJob, :disable_push_to_delius, type: :job do
  let(:nomis_offender_id) { 'G4281GV' }
  let(:remand_nomis_offender_id) { 'G3716UD' }
  let(:crn) { 'X362207' }
  let(:ldu) {  create(:local_delivery_unit) }
  let(:prison) { create(:prison) }
  let(:case_info) { CaseInformation.last }
  let(:team_name) { Faker::Company.name }
  let(:com_forename) { 'Arnold' }
  let(:com_surname) { 'Aardvark' }
  let(:com_email) { 'arnie@aardvark.me' }
  let(:tier) { 'A_2' }

  let(:mock_probation_record) do
    build :probation_record, offender_no: nomis_offender_id,
                             crn: crn,
                             tier: tier,
                             team_description: team_name,
                             ldu_code: ldu.code,
                             ldu_description: ldu.name,
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
      active_vlo: false
    }
  end

  before do
    stub_auth_token

    allow(OffenderService).to receive(:get_probation_record).with(nomis_offender_id)
      .and_return(mock_probation_record)
  end

  shared_examples 'audit event' do
    before do
      allow(RecalculateHandoverDateJob).to receive(:perform_later).and_return(nil)
    end

    let(:audit_event) { AuditEvent.last }

    it 'creates an audit event' do
      expect {
        described_class.perform_now nomis_offender_id
      }.to change(AuditEvent, :count).by(1)
    end

    it 'includes the CaseInformation attribute diffs in the audit event data' do
      described_class.perform_now nomis_offender_id
      expect(audit_event.data).to eq(expected_data)
    end

    it 'includes the word batch in the tags' do
      described_class.perform_now nomis_offender_id
      expect(audit_event.tags).to include('batch')
    end
  end

  context 'when case_information not present' do
    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
    end

    it 'creates case information' do
      expect {
        described_class.perform_now nomis_offender_id
      }.to change(CaseInformation, :count).by(1)

      expect(case_info.attributes.symbolize_keys.except(:created_at, :id, :updated_at, :parole_review_date, :prisoner_id, :welsh_offender))
          .to eq(new_case_information_attributes)
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
            'active_vlo' => false,
            'mappa_level' => nil,
            'manual_entry' => nil,
            'nomis_offender_id' => nomis_offender_id,
            'probation_service' => nil,
            'enhanced_resourcing' => nil,
            'local_delivery_unit_id' => nil
          },
          'after' => new_case_information_attributes.stringify_keys
        }
      end
    end
  end

  context 'when processing a com name' do
    let(:offender_id) { 'A1111AA' }
    let(:nomis_offender_id) { offender_id }

    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: offender_id))
    end

    context 'with a normal COM name' do
      it 'shows com name' do
        expect {
          described_class.perform_now offender_id
        }.to change(CaseInformation, :count).by(1)

        expect(case_info.com_name).to eq("#{com_surname}, #{com_forename}")
      end
    end

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
          described_class.perform_now offender_id
        }.to change(CaseInformation, :count).by(1)

        expect(case_info.com_name).to be_nil
      end
    end
  end

  context 'when tier contains extra characters' do
    let(:tier) { 'B1' }

    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
    end

    it 'creates case information' do
      expect {
        described_class.perform_now nomis_offender_id
      }.to change(CaseInformation, :count).by(1)
      expect(case_info.tier).to eq('B')
    end
  end

  context 'when tier is invalid' do
    let(:tier) { 'X' }

    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
    end

    it 'does not create case information' do
      expect {
        described_class.perform_now nomis_offender_id
      }.not_to change(CaseInformation, :count)
    end
  end

  describe '#probation_service' do
    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
    end

    context 'with an English LDU' do
      let(:ldu) { create(:local_delivery_unit, country: 'England') }

      it 'maps to false' do
        described_class.perform_now(nomis_offender_id)
        expect(case_info.probation_service).to eq('England')
      end
    end

    context 'with an Welsh LDU' do
      let(:ldu) { create(:local_delivery_unit, country: 'Wales') }

      it 'maps to true' do
        described_class.perform_now(nomis_offender_id)
        expect(case_info.probation_service).to eq('Wales')
      end
    end
  end

  describe 'Local Delivery Unit' do
    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
      described_class.perform_now(nomis_offender_id)
    end

    context 'when the LDU code exists in our lookup table' do
      let(:ldu_code) { ldu.code }

      it 'associates it with that LDU' do
        expect(case_info.local_delivery_unit).to eq ldu
      end

      it 'records the LDU code' do
        expect(case_info.ldu_code).to eq ldu_code
      end
    end

    context 'when the LDU code is not in our lookup table' do
      let(:ldu) { OpenStruct.new(code: 'ABC123', name: 'Captain Underpants') }

      it 'imports the record, but without an LDU association' do
        expect(case_info.local_delivery_unit).to be_nil
      end

      it 'records the LDU code' do
        expect(case_info.ldu_code).to eq ldu.code
      end
    end
  end

  context 'when case information already present' do
    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
    end

    let!(:c1) { create(:case_information, tier: 'B', offender: build(:offender, nomis_offender_id: nomis_offender_id)) }
    let(:tier) { 'C' }

    it 'does not create case information' do
      expect {
        described_class.perform_now nomis_offender_id
      }.not_to change(CaseInformation, :count)

      expect(c1.reload.tier).to eq(tier)
    end

    include_examples 'audit event' do
      let(:expected_data) do
        {
          'before' => c1.attributes.except('id', 'created_at', 'updated_at'),
          'after' => (new_case_information_attributes.tap { |a| a[:tier] = tier }).stringify_keys
        }
      end
    end
  end

  context 'when using CRN as the identifier' do
    before do
      stub_offender(build(:nomis_offender, prisonId: prison.code, prisonerNumber: nomis_offender_id))
      allow(OffenderService).to receive(:get_probation_record).with(crn).and_return(mock_probation_record)
      allow(Rails.logger).to receive(:error)
      described_class.perform_now(crn, identifier_type: :crn)
    end

    context 'when the probation record has a NOMIS offender ID' do
      it 'does not log an error' do
        expect(Rails.logger).not_to have_received(:error)
      end
    end

    context 'when the probation record does not have a NOMIS offender ID' do
      let(:nomis_offender_id) { nil }

      it 'logs an error' do
        expect(Rails.logger).to have_received(:error).once
      end
    end
  end

  describe 'pushing handover dates into nDelius' do
    let(:offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:offender_no) { offender.fetch(:prisonerNumber) }
    let(:nomis_offender_id) { offender_no }
    let(:crn) { 'X89264GC' }

    before do
      stub_offender(offender)
    end

    shared_examples 'recalculate handover dates' do
      it "recalculates the offender's handover dates, using the new Case Information data" do
        expect(RecalculateHandoverDateJob).to receive(:perform_later).with(offender_no)
        described_class.perform_now offender_no
      end
    end

    context 'when creating a new Case Information record' do
      include_examples 'recalculate handover dates'
    end

    context 'when updating an existing Case Information record' do
      let!(:case_info) do
        create(:case_information, tier: 'B', offender: build(:offender, nomis_offender_id: offender_no), crn: crn)
      end

      include_examples 'recalculate handover dates'

      it 'does not re-calculate if CaseInformation is unchanged' do
        described_class.perform_now offender_no
        expect(RecalculateHandoverDateJob).not_to receive(:perform_later)
        described_class.perform_now offender_no
      end
    end
  end
end
