require 'rails_helper'

RSpec.describe PomDetail, type: :model do
  it { is_expected.to validate_presence_of(:nomis_staff_id) }
  it { is_expected.to validate_uniqueness_of(:nomis_staff_id) }
  it { is_expected.to validate_presence_of(:working_pattern).with_message('Select number of days worked') }
  it { is_expected.to validate_presence_of(:status) }
end
