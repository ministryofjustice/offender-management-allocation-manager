require 'rails_helper'

RSpec.describe PrisonHelper, type: :helper do
  it 'should work' do
    # prison switcher referrer is sometimes https://gateway.prod.nomis-api.service.hmpps.dsd.io/ (so path is /)
    expect(helper.prison_switcher_path'LEI', '/').to eq('/prisons/LEI/dashboard')
  end
end
