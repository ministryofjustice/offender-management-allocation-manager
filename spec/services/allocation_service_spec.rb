describe AllocationService do
  include ActiveJob::TestHelper

  let(:nomis_offender_id) { 'G7266VD' }
  let(:nomis_staff_id) { 485_758 }
  let(:pom) { build(:pom, staffId: nomis_staff_id, firstName: 'MOIC', lastName: 'INTEGRATION-TESTS') }
  let(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }

  before do
    stub_signed_in_spo_pom(prison.code, nomis_staff_id, 'MOIC_POM')

    stub_pom(pom, emails: [])
    stub_poms(prison.code, [pom])
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

    before do
      allow(EmailService).to receive_messages(send_coworking_primary_email: nil,
                                              send_secondary_email: nil)
    end

    it 'sends an email to both primary and secondary POMS', :aggregate_failures do
      described_class.allocate_secondary(nomis_offender_id: nomis_offender_id,
                                         secondary_pom_nomis_id: secondary_pom_id,
                                         created_by_username: 'MOIC_POM',
                                         message: message
                                        )
      expect(allocation.reload.secondary_pom_nomis_id).to eq(secondary_pom_id)
      expect(allocation.reload.secondary_pom_name).to eq('INTEGRATION-TESTS, MOIC')

      expect(EmailService).to have_received(:send_coworking_primary_email).with(
        allocation: allocation, message: message)
      expect(EmailService).to have_received(:send_secondary_email).with(
        allocation: allocation, message: message,
        pom_nomis_id: secondary_pom_id, pom_firstname: 'MOIC')
    end
  end

  describe '#create_or_update' do
    context 'without an existing' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
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
      let(:nomis_staff_id) { 485_926 }
      let(:nomis_offender) { build(:nomis_offender, prisonerNumber: nomis_offender_id, prisonId: prison.code) }

      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id))
        create(:allocation_history, prison: prison.code, nomis_offender_id: nomis_offender_id)

        stub_offender(nomis_offender)
      end

      it 'can update a record and store a version' do
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
    let(:previous_primary_pom_nomis_id) { 485_637 }
    let(:updated_primary_pom_nomis_id) { 485_926 }
    let(:secondary_pom_nomis_id) { 485_833 }

    before do
      stub_pom_emails(previous_primary_pom_nomis_id, [])
      stub_pom_emails(updated_primary_pom_nomis_id, [])
      stub_pom_emails(secondary_pom_nomis_id, [])
    end

    it 'can retrieve all the POMs email addresses for' do
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
        double(CaseHistory, created_at: '2020-04-09T02:01', primary_pom_name: 'BAYRAM:', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'allocate_primary_pom'),
        double(CaseHistory, created_at: '2020-04-09T13:27', primary_pom_name: 'BAYRAM:', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2020-04-09T13:28', primary_pom_name: 'BAYRAM:', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2020-08-19T11:10', primary_pom_name: 'BAYRAM:', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'MCCANN, KATHERINE', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2020-08-19T11:28', primary_pom_name: 'DICKS:', primary_pom_email: 'dicks@x.com', secondary_pom_name: 'MCCANN, KATHERINE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2020-08-19T11:29', primary_pom_name: 'JENNINGS', primary_pom_email: nil, secondary_pom_name: 'MCCANN, KATHERINE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-03-10T10:52', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'MCCANN, KATHERINE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-04-28T10:23', primary_pom_name: 'DICKS', primary_pom_email: 'dicks@x.com', secondary_pom_name: 'MCCANN, KATHERINE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-06-02T10:59', primary_pom_name: 'DICKS', primary_pom_email: 'dicks@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2021-06-02T10:59', primary_pom_name: 'DICKS', primary_pom_email: 'dicks@x.com', secondary_pom_name: 'ADEOYE', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2021-06-11T13:46', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'ADEOYE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-06-21T11:03', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2021-06-21T11:05', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2021-08-03T07:46', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-03T07:53', primary_pom_name: 'CUFFLIN', primary_pom_email: nil, secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-03T08:29', primary_pom_name: 'ADEOYE', primary_pom_email: nil, secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-03T09:27', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-03T11:38', primary_pom_name: 'ADEOYE', primary_pom_email: nil, secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-04T09:56', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-04T12:37', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-04T13:40', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-10T11:09', primary_pom_name: 'CUFFLIN', primary_pom_email: nil, secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-11T14:26', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-11T14:26', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-12T09:24', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-08-13T15:41', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'JARA DUNCAN, LAURA', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2021-12-29T15:46', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2021-12-29T15:46', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'BATLINER:ANIE', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-01-27T08:20', primary_pom_name: 'CUFFLIN', primary_pom_email: nil, secondary_pom_name: 'BATLINER:ANIE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-01-27T08:20', primary_pom_name: 'CUFFLIN', primary_pom_email: nil, secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-01-27T08:20', primary_pom_name: 'CUFFLIN', primary_pom_email: nil, secondary_pom_name: 'BATLINER:ANIE', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-03-01T15:10', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'BATLINER:ANIE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-01T15:10', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-03-01T15:11', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'CASTIGLIONE', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-03-08T14:51', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: 'CASTIGLIONE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-09T14:06', primary_pom_name: 'ROOKER:', primary_pom_email: 'rooker@x.com', secondary_pom_name: 'CASTIGLIONE', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:51', primary_pom_name: 'ROOKER:', primary_pom_email: 'rooker@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:55', primary_pom_name: 'BAYRAM', primary_pom_email: 'bayram@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:56', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:56', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:56', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:56', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:56', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T08:58', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-03-31T11:48', primary_pom_name: 'BATLINER:', primary_pom_email: 'batliner@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-04-22T15:08', primary_pom_name: 'POM:', primary_pom_email: 'pom@x.com', secondary_pom_name: nil, event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-04-25T12:54', primary_pom_name: 'POM:', primary_pom_email: 'pom@x.com', secondary_pom_name: 'ROOKER:', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-10-26T11:41', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: 'ROOKER:', event: 'reallocate_primary_pom'),
        double(CaseHistory, created_at: '2022-11-21T17:59', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2022-11-21T17:59', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: 'QAZI, ASFAND', event: 'allocate_secondary_pom'),
        double(CaseHistory, created_at: '2023-02-08T12:12', primary_pom_name: 'ADAMS:', primary_pom_email: 'adams@x.com', secondary_pom_name: nil, event: 'deallocate_secondary_pom'),
        double(CaseHistory, created_at: '2023-02-16T12:13', primary_pom_name: 'DUCKETT', primary_pom_email: nil, secondary_pom_name: nil, event: 'reallocate_primary_pom')
      ]
    end

    before { allow(described_class).to receive(:history).and_return(case_histories) }

    it 'works' do
      expect(terms).to eq([
        { started_at: '2020-04-09T02:01', ended_at: '2020-08-19T11:28', name: 'BAYRAM:', email: 'bayram@x.com' },
        { started_at: '2020-08-19T11:28', ended_at: '2020-08-19T11:29', name: 'DICKS:', email: 'dicks@x.com' },
        { started_at: '2020-08-19T11:29', ended_at: '2021-03-10T10:52', name: 'JENNINGS', email: nil },
        { started_at: '2021-03-10T10:52', ended_at: '2021-04-28T10:23', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2021-04-28T10:23', ended_at: '2021-06-11T13:46', name: 'DICKS', email: 'dicks@x.com' },
        { started_at: '2021-06-11T13:46', ended_at: '2021-08-03T07:53', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2021-08-03T07:53', ended_at: '2021-08-03T08:29', name: 'CUFFLIN', email: nil },
        { started_at: '2021-08-03T08:29', ended_at: '2021-08-03T09:27', name: 'ADEOYE', email: nil },
        { started_at: '2021-08-03T09:27', ended_at: '2021-08-03T11:38', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2021-08-03T11:38', ended_at: '2021-08-04T09:56', name: 'ADEOYE', email: nil },
        { started_at: '2021-08-04T09:56', ended_at: '2021-08-10T11:09', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2021-08-10T11:09', ended_at: '2021-08-11T14:26', name: 'CUFFLIN', email: nil },
        { started_at: '2021-08-11T14:26', ended_at: '2022-01-27T08:20', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2022-01-27T08:20', ended_at: '2022-03-01T15:10', name: 'CUFFLIN', email: nil },
        { started_at: '2022-03-01T15:10', ended_at: '2022-03-09T14:06', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2022-03-09T14:06', ended_at: '2022-03-31T08:55', name: 'ROOKER:', email: 'rooker@x.com' },
        { started_at: '2022-03-31T08:55', ended_at: '2022-03-31T08:56', name: 'BAYRAM', email: 'bayram@x.com' },
        { started_at: '2022-03-31T08:56', ended_at: '2022-03-31T11:48', name: 'ADAMS:', email: 'adams@x.com' },
        { started_at: '2022-03-31T11:48', ended_at: '2022-04-22T15:08', name: 'BATLINER:', email: 'batliner@x.com' },
        { started_at: '2022-04-22T15:08', ended_at: '2022-10-26T11:41', name: 'POM:', email: 'pom@x.com' },
        { started_at: '2022-10-26T11:41', ended_at: '2023-02-16T12:13', name: 'ADAMS:', email: 'adams@x.com' },
        { started_at: '2023-02-16T12:13', ended_at: nil, name: 'DUCKETT', email: nil },
      ])
    end
  end
end
