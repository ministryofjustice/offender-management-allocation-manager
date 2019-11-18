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
             primary_pom_name: 'JONES, ROSS')
    }

    it 'sends an email to both primary and secondary POMS', vcr: { cassette_name: :allocation_service_allocate_secondary } do
      expect {
        described_class.allocate_secondary(nomis_offender_id: nomis_offender_id,
                                           secondary_pom_nomis_id: secondary_pom_id,
                                           created_by_username: 'PK000223',
                                           message: message
        )
        expect(allocation.reload.secondary_pom_nomis_id).to eq(secondary_pom_id)
        expect(allocation.reload.secondary_pom_name).to eq('POBEE-NORRIS, KATH')
      }.to change(enqueued_jobs, :count).by(2)

      primary_email_job, secondary_email_job = enqueued_jobs.last(2)

      # mail telling the primary POM about the co-working POM
      primary_args_hash = primary_email_job[:args][3]['args'][0]
      secondary_args_hash = secondary_email_job[:args][3]['args'][0]
      expect(primary_args_hash).
        to match(
          hash_including(
            "message" => message,
            "pom_name" => "Ross",
            "offender_name" => "Abdoria, Ongmetain",
            "nomis_offender_id" => "G7806VO",
            "coworking_pom_name" => "POBEE-NORRIS, KATH",
            "pom_email" => "Ross.jonessss@digital.justice.gov.uk",
            "url" => "http://localhost:3000/prisons/LEI/caseload"
          ))

      # message telling co-working POM who the Primary POM is.
      expect(secondary_args_hash).
        to match(
          hash_including(
            "message" => message,
            "pom_name" => "Kath",
            "offender_name" => "Abdoria, Ongmetain",
            "nomis_offender_id" => "G7806VO",
            "responsibility" => "supporting",
            "responsible_pom_name" => 'JONES, ROSS',
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
        event_trigger: AllocationVersion::USER,
        created_by_username: 'PK000223'
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
        event: AllocationVersion::REALLOCATE_PRIMARY_POM,
        created_by_username: 'PK000223'
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

      allocations = described_class.active_allocations([first_offender_id, second_offender_id], leeds_prison)

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

  it 'can get the current allocated primary POM', versioning: true, vcr: { cassette_name: 'current_allocated_primary_pom' }  do
    nomis_offender_id = 'G2911GD'
    previous_primary_pom_nomis_id = 485_637
    updated_primary_pom_nomis_id = 485_752

    allocation = create(
      :allocation_version,
      nomis_offender_id: nomis_offender_id,
      primary_pom_nomis_id: previous_primary_pom_nomis_id)

    allocation.update!(
      primary_pom_nomis_id: updated_primary_pom_nomis_id,
      event: AllocationVersion::REALLOCATE_PRIMARY_POM
    )

    current_pom = described_class.current_pom_for(nomis_offender_id, 'LEI')

    expect(current_pom.full_name).to eq("Jones, Ross")
    expect(current_pom.grade).to eq("Probation POM")
  end

  it 'can set the correct com_name', versioning: true, vcr: { cassette_name: 'allocation_service_com_name' }  do
    nomis_offender_id = 'G2911GD'

    create(:delius_data, noms_no: nomis_offender_id, offender_manager: 'Bob')

    params = {
      nomis_offender_id: nomis_offender_id,
      prison: 'LEI',
      allocated_at_tier: 'A',
      primary_pom_nomis_id: 485_833,
      primary_pom_allocated_at: DateTime.now.utc,
      nomis_booking_id: 1,
      recommended_pom_type: 'probation',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER,
      created_by_username: 'PK000223'
    }

    described_class.create_or_update(params)

    alloc = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id)
    expect(alloc.com_name).to eq('Bob')
  end
end
