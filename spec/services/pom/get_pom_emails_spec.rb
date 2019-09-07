require 'rails_helper'

describe POM::GetPomEmails do
  let(:staff_id) { 485_737 }
  let(:other_staff_id) { 485_637 }

  before(:each) {
    PomDetail.create(nomis_staff_id: :other_staff_id, working_pattern: 1.0, status: 'inactive')
  }
end
