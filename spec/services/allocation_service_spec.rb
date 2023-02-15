require 'rails_helper'

describe AllocationService do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G7266VD' }

  before do
    # needed as create_or_update calls a NOMIS API
    signin_spo_user
  end

  describe '#allocate_secondary', :queueing do
    let(:moic_test_id) { 485_758 }
    let(:ross_id) { 485_926 }
    let(:primary_pom_id) { ross_id }
    let(:secondary_pom_id) { moic_test_id }
    let(:message) { 'Additional text' }

    let!(:allocation) do
      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
      create(:allocation_history,
             prison: 'LEI',
             nomis_offender_id: nomis_offender_id,
             primary_pom_nomis_id: primary_pom_id,
             primary_pom_name: 'Pom, Moic')
    end

    it 'sends an email to both primary and secondary POMS', vcr: { cassette_name: 'prison_api/allocation_service_allocate_secondary' } do
      expect {
        described_class.allocate_secondary(nomis_offender_id: nomis_offender_id,
                                           secondary_pom_nomis_id: secondary_pom_id,
                                           created_by_username: 'MOIC_POM',
                                           message: message
                                          )
        expect(allocation.reload.secondary_pom_nomis_id).to eq(secondary_pom_id)
        expect(allocation.reload.secondary_pom_name).to eq('INTEGRATION-TESTS, MOIC')
      }.to change(enqueued_jobs, :count).by(2)

      primary_email_job, secondary_email_job = enqueued_jobs.last(2)

      # mail telling the primary POM about the co-working POM
      primary_args_hash = primary_email_job[:args][3]['args'][0]
      secondary_args_hash = secondary_email_job[:args][3]['args'][0]
      expect(primary_args_hash)
        .to match(
          hash_including(
            "message" => message,
            "offender_name" => "Annole, Omistius",
            "nomis_offender_id" => nomis_offender_id,
            "pom_email" => "pom@digital.justice.gov.uk",
            "pom_name" => "Moic",
            "url" => "http://localhost:3000/prisons/LEI/staff/#{primary_pom_id}/caseload"
          ))

      # message telling co-working POM who the Primary POM is.
      expect(secondary_args_hash)
        .to match(
          hash_including(
            "message" => message,
            "pom_name" => "Moic",
            "offender_name" => "Annole, Omistius",
            "nomis_offender_id" => nomis_offender_id,
            "responsibility" => "responsible",
            "responsible_pom_name" => 'Pom, Moic',
            "pom_email" => "ommiicc@digital.justice.gov.uk",
            "url" => "http://localhost:3000/prisons/LEI/staff/#{secondary_pom_id}/caseload"
          ))
    end
  end

  describe '#create_or_update' do
    context 'without an existing' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
        stub_auth_token
        stub_request(:get, "#{ApiHelper::T3}/users/MOIC_POM")
          .to_return(body: { staffId: 1, firstName: "MOIC", lastName: 'POM' }.to_json)
        stub_pom_emails 1, []
        stub_offender(build(:nomis_offender, prisonId: prison_code, prisonerNumber: nomis_offender_id))
        stub_poms prison_code, [pom]
      end

      let(:prison_code) { create(:prison).code }
      let(:pom) { build(:pom, staffId: 485_833) }

      it 'can create a new record' do
        params = {
          nomis_offender_id: nomis_offender_id,
          prison: prison_code,
          allocated_at_tier: 'A',
          primary_pom_nomis_id: 485_833,
          primary_pom_allocated_at: Time.zone.now.utc,
          recommended_pom_type: 'probation',
          event: AllocationHistory::ALLOCATE_PRIMARY_POM,
          event_trigger: AllocationHistory::USER,
          created_by_username: 'MOIC_POM'
        }

        expect {
          described_class.create_or_update(params)
        }.to change(AllocationHistory, :count).by(1)
      end
    end

    context 'when one already exists' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
        create(:allocation_history, prison: 'LEI', nomis_offender_id: nomis_offender_id)
      end

      it 'can update a record and store a version', vcr: { cassette_name: 'prison_api/allocation_service_update_allocation_spec' } do
        update_params = {
          nomis_offender_id: nomis_offender_id,
          allocated_at_tier: 'B',
          primary_pom_nomis_id: 485_926,
          event: AllocationHistory::REALLOCATE_PRIMARY_POM,
          created_by_username: 'MOIC_POM'
        }

        expect {
          expect {
            described_class.create_or_update(update_params)
          }.not_to change(AllocationHistory, :count)
        }.to change { AllocationHistory.find_by(nomis_offender_id: nomis_offender_id).versions.count }.by(1)
      end
    end
  end

  describe '#allocation_history_pom_emails' do
    it 'can retrieve all the POMs email addresses for ', vcr: { cassette_name: 'prison_api/allocation_service_history_spec' } do
      previous_primary_pom_nomis_id = 485_637
      updated_primary_pom_nomis_id = 485_926
      secondary_pom_nomis_id = 485_833

      allocation = create(
        :allocation_history,
        prison: build(:prison).code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: previous_primary_pom_nomis_id)

      allocation.update!(
        primary_pom_nomis_id: updated_primary_pom_nomis_id,
        event: AllocationHistory::REALLOCATE_PRIMARY_POM
      )

      allocation.update!(
        secondary_pom_nomis_id: secondary_pom_nomis_id,
        event: AllocationHistory::ALLOCATE_SECONDARY_POM
      )

      alloc = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id)
      emails = described_class.allocation_history_pom_emails(alloc)

      expect(emails.count).to eq(3)
    end
  end

  describe '.pom_terms' do
    subject(:terms) { described_class.pom_terms(case_histories) }

    let(:case_histories) do
      [
        double(CaseHistory, created_at: -3, primary_pom_name: 'APPLES'),
        double(CaseHistory, created_at: -2, primary_pom_name: 'PEARS'),
        double(CaseHistory, created_at: -1, primary_pom_name: 'SPUDS'),
        double(CaseHistory, created_at:  0,   primary_pom_name: 'FIGS')
      ]
    end

    before { allow(described_class).to receive(:history).and_return(case_histories) }

    it 'works' do
      expect(terms).to eq([
        { name: 'APPLES', started_at: -3, ended_at: -2 },
        { name: 'PEARS',  started_at: -2, ended_at: -1 },
        { name: 'SPUDS',  started_at: -1, ended_at:  0 },
        { name: 'FIGS',   started_at:  0, ended_at: nil }
      ])
    end
  end
end
