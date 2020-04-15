require 'rails_helper'

RSpec.describe DeliusImportError, type: :model do
  it {
    expect(subject).to validate_presence_of :nomis_offender_id
    expect(subject).to validate_inclusion_of(:error_type).in_array([0, 1, 2, 4, 5, 6])
  }
end
