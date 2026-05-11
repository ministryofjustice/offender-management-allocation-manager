require 'rails_helper'

RSpec.describe ComplexityNewHistory do
  subject(:presenter) { described_class.new(history) }

  let(:timestamp) { Time.utc(2024, 1, 15, 10, 30, 0) }
  let(:history) do
    {
      createdTimeStamp: timestamp,
      level: 'high',
      sourceUser: 'joebloggs'
    }
  end

  describe '#created_at' do
    it 'returns the timestamp in local time' do
      expect(presenter.created_at).to eq(timestamp.getlocal)
    end
  end

  describe '#level' do
    it 'titleizes the level' do
      expect(presenter.level).to eq('High')
    end
  end

  describe '#prison' do
    it 'returns nil' do
      expect(presenter.prison).to be_nil
    end
  end

  describe '#to_partial_path' do
    it 'returns the complexity new partial' do
      expect(presenter.to_partial_path).to eq('case_history/complexity/new')
    end
  end

  describe '#created_by_name' do
    it 'returns the NOMIS user full name' do
      allow(HmppsApi::NomisUserRolesApi).to receive(:user_details).with('joebloggs').and_return(
        instance_double(HmppsApi::UserDetails, first_name: 'Joe', last_name: 'Bloggs')
      )

      expect(presenter.created_by_name).to eq('Joe Bloggs')
    end

    it 'returns nil when the source user is blank' do
      history[:sourceUser] = nil

      expect(presenter.created_by_name).to be_nil
    end
  end
end
