require 'rails_helper'

RSpec.describe OverrideHelper do
  describe 'gets a complex override reason label' do
    it "can get for a prison owned offender" do
      # Nil release date means RESPONSIBLE which means case owner is Prison
      off = Nomis::Models::Offender.new
      off.sentence = Nomis::Models::SentenceDetail.new

      expect(off.case_owner).to eq('Prison')
      expect(complex_reason_label(off)).to eq('Prisoner assessed as not suitable for a prison officer POM')
    end

    it "can get for a probation owned offender" do
      off = Nomis::Models::Offender.new
      off.sentence = Nomis::Models::SentenceDetail.new
      off.sentence.release_date = Time.zone.today

      expect(off.case_owner).to eq('Probation')
      expect(complex_reason_label(off)).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
    end
  end
end
