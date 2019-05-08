require 'rails_helper'

RSpec.describe OverrideHelper do
  describe 'gets a complex override reason label' do
    it "can get for a prison owned offender" do
      expect(complex_reason_label('Prison officer')).to eq('Prisoner assessed as not suitable for a prison officer POM')
    end

    it "can get for a probation owned offender" do
      expect(complex_reason_label('Probation officer')).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
    end
  end
end
