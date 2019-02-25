require 'rails_helper'

describe Nomis::Elite2::MovementApi do
  describe 'Movements for date' do
    it 'can get movements on a specific date',
      vcr: { cassette_name: :movement_api_on_date } do

      movements = described_class.movements_on_date(Date.iso8601('2019-02-20'))
      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(3)
      expect(movements.first).to be_kind_of(Nomis::Models::Movement)
    end
  end
end
