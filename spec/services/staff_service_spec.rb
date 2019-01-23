require 'rails_helper'

describe StaffService, vcr: { cassette_name: :staff_service_spec } do
  it 'gets a list of Prison Offender Managers' do
    leeds = 'LEI'
    poms = subject.get_prisoner_offender_managers(leeds)

    expect(poms.data).to be_kind_of(Array)
  end
end
