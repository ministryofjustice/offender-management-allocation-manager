require 'rails_helper'

RSpec.describe ParoleRecord, type: :model do
  it 'always belongs to an offender' do
    expect(build(:parole_record).offender).not_to be_nil
  end
end
