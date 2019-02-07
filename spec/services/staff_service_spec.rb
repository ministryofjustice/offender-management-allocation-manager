require 'rails_helper'

describe StaffService, vcr: { cassette_name: :staff_service_spec } do
  it 'gets a list of Prison Offender Managers' do
    leeds = 'LEI'
    poms = described_class.get_prisoner_offender_managers(leeds)

    expect(poms).to be_empty
  end
end
