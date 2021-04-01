require 'rails_helper'

RSpec.describe PomHelper do
  describe 'format_working_pattern' do
    it "formats a POM's working pattern" do
      expect(format_working_pattern(1.0)).to eq('Full time')
    end
  end

  describe 'fetch_pom_name', vcr: { cassette_name: 'prison_api/pom_helper_fetch_pom_name' } do
    it 'fetches the POM name from NOMIS' do
      expect(fetch_pom_name(485_926)).to eq('POM, MOIC')
    end
  end

  describe 'status' do
    it "renames 'active' status to available" do
      pom = build(:pom, staffId: 2005,  status: 'active')
      expect(status(pom)).to eq('available')
    end

    it "does not rename 'inactive' status" do
      pom = build(:pom, staffId: 2005,  status: 'inactive')
      expect(status(pom)).to eq('inactive')
    end

    it "does not rename 'unavailable' status" do
      pom = build(:pom, staffId: 2005,  status: 'unavailable')
      expect(status(pom)).to eq('unavailable')
    end
  end
end
