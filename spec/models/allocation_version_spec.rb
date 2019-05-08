require 'rails_helper'

RSpec.describe AllocationVersion, type: :model do
  it { is_expected.to validate_presence_of(:nomis_offender_id) }
  it { is_expected.to validate_presence_of(:nomis_booking_id) }
  it { is_expected.to validate_presence_of(:prison) }
  it { is_expected.to validate_presence_of(:allocated_at_tier) }
  it { is_expected.to validate_presence_of(:event) }
  it { is_expected.to validate_presence_of(:event_trigger) }

  describe 'Version' do
    it 'creates a version when updating a record', versioning: true do
      attributes = {
        nomis_offender_id: 123_456,
        prison: 'LEI',
        allocated_at_tier: 'A',
        primary_pom_name: 'Bob Jones',
        primary_pom_nomis_id: 456_789,
        nomis_booking_id: 896_456,
        event: 0,
        event_trigger: 0
      }

      allocation_version = AllocationVersion.create!(attributes)

      expect(allocation_version.versions.count).to be(1)

      allocation_version.update(allocated_at_tier: 'B')

      expect(allocation_version.versions.count).to be(2)
      expect(allocation_version.versions.last.reify.allocated_at_tier).to eq('A')
    end
  end
end
