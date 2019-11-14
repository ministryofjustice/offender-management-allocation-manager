require 'rails_helper'

RSpec.describe StaffMember, type: :model, vcr: { cassette_name: :staff_member_things } do
  describe '#full_name' do
    let(:pom) { described_class.new(485_846) }

    it 'gets the full name' do
      expect(pom.full_name).to eq('Dicks, Stephen')
    end
  end
end
