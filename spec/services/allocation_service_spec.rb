require 'rails_helper'

RSpec.describe AllocationService do
  let!(:allocation) {
    described_class.create_or_update(
      primary_pom_nomis_id: 485_595,
      nomis_offender_id: 'G2911GD',
      created_by_username: 'PK000223',
      nomis_booking_id: 1,
      allocated_at_tier: 'A',
      prison: 'LEI',
      created_at: '01/01/2019',
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    )
  }

  let(:mock_email_service) { double('email_service_mock') }

  before do
    allow(mock_email_service).to receive(:send_allocation_email)
    allow(EmailService).to receive(:instance).and_return(mock_email_service)
  end

  it 'can create a new record where none exists', vcr: { cassette_name: :allocation_service_create_allocation_version } do
    params = {
      nomis_offender_id: 'G2911GD',
      prison: 'LEI',
      allocated_at_tier: 'A',
      primary_pom_nomis_id: 485_595,
      nomis_booking_id: 1,
      event: AllocationVersion::ALLOCATE_PRIMARY_POM,
      event_trigger: AllocationVersion::USER
    }

    described_class.create_or_update(params)
    expect(AllocationVersion.count).to be(1)
  end

  it 'can update a record and store a version where one already exists', versioning: true, vcr: { cassette_name: :allocation_service_update_allocation_version } do
    update_params = {
      nomis_offender_id: 'G2911GD',
      allocated_at_tier: 'B',
      primary_pom_nomis_id: 485_752,
      event: AllocationVersion::REALLOCATE_PRIMARY_POM
    }

    described_class.create_or_update(update_params)

    expect(AllocationVersion.count).to be(1)
    expect(AllocationVersion.find_by(nomis_offender_id: 'G2911GD').versions.count).to be(2)
  end

  it "Can get all allocations", vcr: { cassette_name: :allocation_service_get_allocations } do
    allocations = described_class.all_allocations

    expect(allocations).to be_instance_of(Hash)
    expect(allocations['G2911GD']).to be_kind_of(AllocationVersion)
  end

  it "Can get previous poms for an offender where there are none", versioning: true, vcr: { cassette_name: :allocation_service_previous_allocations_none } do
    staff_ids = described_class.previously_allocated_poms(allocation.nomis_offender_id)

    expect(staff_ids).to eq([])
  end

  it "Can get previous poms for an offender where there are some", versioning: true, vcr: { cassette_name: :allocation_service_previous_allocations } do
    allocation.update!(primary_pom_nomis_id: 485_752)

    staff_ids = described_class.previously_allocated_poms(allocation.nomis_offender_id)

    expect(staff_ids.count).to eq(1)
    expect(staff_ids.first).to eq(485_595)
  end

  # TODO: Reinstate after changes to allocation history confirmed
  xit "Can get the allocation history for an offender", versioning: true, vcr: { cassette_name: 'allocation_service_offender_history' } do
    described_class.create_or_update(
      nomis_offender_id: allocation.nomis_offender_id,
      primary_pom_nomis_id: 485_752,
      event: AllocationVersion::REALLOCATE_PRIMARY_POM
    )
    described_class.create_or_update(
      nomis_offender_id: allocation.nomis_offender_id,
      allocated_at_tier: 'D',
      event: :reallocate_primary_pom
    )

    allocations = described_class.offender_allocation_history(allocation.nomis_offender_id)

    expect(allocations.count).to eq(1)
    expect(allocations.first.nomis_offender_id).to eq(allocation.nomis_offender_id)
    expect(allocations.first.event).to eq('allocate_primary_pom')
    expect(allocations.second.nomis_booking_id).to eq(first_reallocation.nomis_booking_id)
    expect(allocations.last.nomis_booking_id).to eq(second_reallocation.nomis_booking_id)
    expect(allocations.last.prison).to eq('PVI')
  end
end
