require 'rails_helper'

describe AllocationService do
  let(:mock_email_service) { double('email_service_mock') }

  before do
    allow(mock_email_service).to receive(:send_email)
    allow(EmailService).to receive(:instance).and_return(mock_email_service)
  end

  it 'can create a new record where none exists', versioning: true, vcr: { cassette_name: :allocation_service_create_allocation_version } do
    params = {
      nomis_offender_id: 'G2911GD',
      prison: 'LEI',
      allocated_at_tier: 'A',
      primary_pom_nomis_id: 485_595,
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

  it "Can get all allocations", vcr: { cassette_name: :allocation_service_get_allocations } do
    allocation = create(:allocation_version)
    allocations = described_class.all_allocations

    expect(allocations).to be_instance_of(Hash)
    expect(allocations[allocation.nomis_offender_id]).to be_kind_of(AllocationVersion)
  end

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

  it "Can get the allocation history for an offender", versioning: true, vcr: { cassette_name: 'allocation_service_offender_history' } do
    nomis_offender_id = 'GHF1234'

    described_class.create_or_update(
      nomis_offender_id: nomis_offender_id,
      nomis_booking_id: 1,
      primary_pom_nomis_id: 485_766,
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
