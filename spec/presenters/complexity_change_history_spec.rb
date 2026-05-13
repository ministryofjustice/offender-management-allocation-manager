require 'rails_helper'

RSpec.describe ComplexityChangeHistory do
  subject(:presenter) { described_class.new(previous, current) }

  let(:previous) { { level: 'low' } }
  let(:current) do
    {
      level: 'medium',
      createdTimeStamp: Time.utc(2024, 1, 15, 10, 30, 0),
      sourceUser: 'joebloggs',
      notes: 'Risk profile increased'
    }
  end

  before do
    allow(HmppsApi::NomisUserRolesApi).to receive(:user_details).with('joebloggs').and_return(
      instance_double(HmppsApi::UserDetails, first_name: 'Joe', last_name: 'Bloggs')
    )
  end

  it 'delegates the current change details and exposes the previous level and reasons' do
    expect(presenter.previous_level).to eq('Low')
    expect(presenter.level).to eq('Medium')
    expect(presenter.created_by_name).to eq('Joe Bloggs')
    expect(presenter.reasons).to eq('Risk profile increased')
    expect(presenter.to_partial_path).to eq('case_history/complexity/change')
  end
end
