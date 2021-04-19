# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomDetail, type: :model do
  it { is_expected.to validate_presence_of(:nomis_staff_id) }
  it { expect(create(:pom_detail, prison_code: build(:prison).code)).to validate_uniqueness_of(:nomis_staff_id).scoped_to(:prison_code) }
  it { is_expected.to validate_presence_of(:working_pattern).with_message('Select number of days worked') }
  it { is_expected.to validate_presence_of(:status) }
end
