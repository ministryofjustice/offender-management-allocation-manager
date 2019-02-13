require 'rails_helper'

RSpec.describe Override, type: :model do
  it { is_expected.to validate_presence_of(:nomis_offender_id) }
  it { is_expected.to validate_presence_of(:nomis_staff_id) }
  it { is_expected.to validate_presence_of(:override_reasons) }
end
