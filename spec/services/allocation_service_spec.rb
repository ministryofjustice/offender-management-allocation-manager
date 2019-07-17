require 'rails_helper'

describe AllocationService do
  include ActiveJob::TestHelper

  before do
    # needed as create_or_update calls a NOMIS API
    signin_user
  end

  describe '#allocate_secondary', :queueing do
    let(:kath_id) { 485_637 }
    let(:ross_id) { 485_752 }
    let(:nomis_offender_id) { 'G7806VO' }
    let(:primary_pom_id) { ross_id }
    let(:secondary_pom_id) { kath_id }
    let(:message) { 'Additional text' }

    let!(:allocation) {
      create(:allocation_version,
             nomis_offender_id: nomis_offender_id,
             primary_pom_nomis_id: primary_pom_id,
             primary_pom_name: 'ROSS JONES')
    }

    it 'sends an email to both primary and secondary POMS', vcr: { cassette_name: :allocation_service_allocate_secondary } do
      expect {
        described_class.allocate_secondary(nomis_offender_id: nomis_offender_id,
                                           secondary_pom_nomis_id: secondary_pom_id,
                                           created_by_username: 'PK000223',
                                           message: message
        )
        expect(allocation.reload.secondary_pom_nomis_id).to eq(secondary_pom_id)
        expect(allocation.reload.secondary_pom_name).to eq('KATH POBEE-NORRIS')
      }.to change(enqueued_jobs, :count).by(2)

      primary_email_job, secondary_email_job = enqueued_jobs.last(2)

      # mail telling the primary POM about the co-working POM
      expect(primary_email_job[:args][3]).
        to match(
          hash_including(
            "message" => message,
            "pom_name" => "Ross",
            "offender_name" => "Abdoria, Ongmetain",
            "nomis_offender_id" => "G7806VO",
            "coworking_pom_name" => "KATH POBEE-NORRIS",
            "pom_email" => "Ross.jonessss@digital.justice.gov.uk",
            "url" => "http://localhost:3000/prisons/LEI/caseload"
          ))

      # message telling co-working POM who the Primary POM is.
      expect(secondary_email_job[:args][3]).
        to match(
          hash_including(
            "message" => message,
            "pom_name" => "Kath",
            "offender_name" => "Abdoria, Ongmetain",
            "nomis_offender_id" => "G7806VO",
            "responsibility" => "supporting",
            "responsible_pom_name" => 'ROSS JONES',
            "pom_email" => "kath.pobee-norris@digital.justice.gov.uk",
            "url" => "http://localhost:3000/prisons/LEI/caseload"
          ))
    end
  end

  describe '#create_or_update' do
    it 'can create a new record where none exists', versioning: true, vcr: { cassette_name: :allocation_service_create_allocation_version } do
      params = {
        nomis_offender_id: 'G2911GD',
        prison: 'LEI',
        allocated_at_tier: 'A',
        primary_pom_nomis_id: 485_833,
        primary_pom_allocated_at: DateTime.now.utc,
        nomis_booking_id: 1,
        recommended_pom_type: 'probation',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      }

      described_class.create_or_update(params)
      expect(AllocationVersion.count).to be(1)
    end

    it 'can update a record and store a version where one already exists', versioning: true, vcr: { cassette_name: :allocation_service_update_allocation_version } do
      nomis_offender_id = 'G2911GD'

      create(:allocation_version, nomis_offender_id: nomis_offender_id)

      update_params = {
        nomis_offender_id: nomis_offender_id,
        allocated_at_tier: 'B',
        primary_pom_nomis_id: 485_752,
        event: AllocationVersion::REALLOCATE_PRIMARY_POM
      }

      described_class.create_or_update(update_params)

      expect(AllocationVersion.count).to be(1)
      expect(AllocationVersion.find_by(nomis_offender_id: nomis_offender_id).versions.count).to be(2)
    end
  end

  describe '#all_allocations' do
    it "Can get all allocations", vcr: { cassette_name: :allocation_service_get_allocations } do
      allocation = create(:allocation_version)
      allocations = described_class.all_allocations

      expect(allocations).to be_instance_of(Hash)
      expect(allocations[allocation.nomis_offender_id]).to be_kind_of(AllocationVersion)
    end
  end

  describe '#allocations' do
    it "Can get allocations by prison", vcr: { cassette_name: :allocation_service_get_allocations_by_prison } do
      first_offender_id = 'JSHD000NN'
      second_offender_id = 'SDHH87GD'
      leeds_prison = 'LEI'

      create(
        :allocation_version,
        nomis_offender_id: first_offender_id,
        prison: leeds_prison
      )

      create(
        :allocation_version,
        nomis_offender_id: second_offender_id,
        prison: 'USK'
      )

      allocations = described_class.allocations([first_offender_id, second_offender_id], leeds_prison)

      expect(allocations.keys.count).to be(1)
      expect(allocations.keys.first).to eq(first_offender_id)
    end
  end

  describe '#previously_allocated_poms' do
    it "Can get previous poms for an offender where there are none", versioning: true, vcr: { cassette_name: :allocation_service_previous_allocations_none } do
      staff_ids = described_class.previously_allocated_poms('GDF7657')

      expect(staff_ids).to eq([])
    end

    it "Can get previous poms for an offender where there are some", versioning: true, vcr: { cassette_name: :allocation_service_previous_allocations } do
      nomis_offender_id = 'GHF1234'
      previous_primary_pom_nomis_id = 345_567
      updated_primary_pom_nomis_id = 485_752

      allocation = create(
        :allocation_version,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: previous_primary_pom_nomis_id)

      allocation.update!(
        primary_pom_nomis_id: updated_primary_pom_nomis_id,
        event: AllocationVersion::REALLOCATE_PRIMARY_POM
      )

      staff_ids = described_class.previously_allocated_poms(nomis_offender_id)

      expect(staff_ids.count).to eq(1)
      expect(staff_ids.first).to eq(previous_primary_pom_nomis_id)
    end
  end

  describe '#offender_allocation_history' do
    it "Can get the allocation history for an offender", versioning: true, vcr: { cassette_name: 'allocation_service_offender_history' } do
      nomis_offender_id = 'G7806VO'

      described_class.create_or_update(
        nomis_offender_id: nomis_offender_id,
        nomis_booking_id: 1,
        primary_pom_nomis_id: 485_833,
        allocated_at_tier: 'A',
        prison: 'PVI',
        recommended_pom_type: 'probation',
        event: AllocationVersion::REALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      )
      described_class.create_or_update(
        nomis_offender_id: nomis_offender_id,
        nomis_booking_id: 1,
        primary_pom_nomis_id: 485_737,
        allocated_at_tier: 'A',
        prison: 'LEI',
        recommended_pom_type: 'probation',
        event: AllocationVersion::ALLOCATE_PRIMARY_POM,
        event_trigger: AllocationVersion::USER
      )

      allocation_list = described_class.offender_allocation_history(nomis_offender_id)

      expect(allocation_list.count).to eq(2)
      expect(allocation_list.first.nomis_offender_id).to eq(nomis_offender_id)
      expect(allocation_list.first.event).to eq('allocate_primary_pom')
      expect(allocation_list.second.nomis_booking_id).to eq(1)
      expect(allocation_list.last.prison).to eq('PVI')
    end
  end

  describe '#allocation_history_pom_emails' do
    it "can get email addresses of POM's who have been allocated to an offender given the allocation history", versioning: true, vcr: { cassette_name: 'pom_emails_on_offender_history' } do
      nomis_offender_id = 'GHF1234'
      previous_primary_pom_nomis_id = 485_752
      updated_primary_pom_nomis_id = 485_637
      primary_pom_without_email_id = 485_636

      allocation = create(
        :allocation_version,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: previous_primary_pom_nomis_id)

      allocation.update!(
        primary_pom_nomis_id: updated_primary_pom_nomis_id,
        event: AllocationVersion::REALLOCATE_PRIMARY_POM
      )

      allocation.update!(
        primary_pom_nomis_id: primary_pom_without_email_id,
        event: AllocationVersion::REALLOCATE_PRIMARY_POM
      )

      allocation.update!(
        primary_pom_nomis_id: updated_primary_pom_nomis_id,
        event: AllocationVersion::REALLOCATE_PRIMARY_POM
      )

      allocation_list = described_class.offender_allocation_history(nomis_offender_id)
      pom_emails = described_class.allocation_history_pom_emails(allocation_list)

      expect(pom_emails.count).to eq(3)
      expect(pom_emails[primary_pom_without_email_id]).to eq(nil)
      expect(pom_emails[updated_primary_pom_nomis_id]).to eq('kath.pobee-norris@digital.justice.gov.uk')
      expect(pom_emails[previous_primary_pom_nomis_id]).to eq('Ross.jonessss@digital.justice.gov.uk')
    end
  end
end
