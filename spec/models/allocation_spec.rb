require 'rails_helper'

RSpec.describe Allocation, type: :model do
  it { is_expected.to validate_presence_of(:nomis_offender_id) }
  it { is_expected.to validate_presence_of(:nomis_booking_id) }
  it { is_expected.to validate_presence_of(:prison) }
  it { is_expected.to validate_presence_of(:allocated_at_tier) }
  it { is_expected.to validate_presence_of(:created_by_username) }
end
