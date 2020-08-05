require 'rails_helper'

RSpec.describe PomHelper do
  describe 'format_working_pattern' do
    it "formats a POM's working pattern" do
      expect(format_working_pattern(1.0)).to eq('Full time')
    end
  end

  describe 'fetch_pom_name', vcr: { cassette_name: :pom_helper_fetch_pom_name } do
    it 'fetches the POM name from NOMIS' do
      expect(fetch_pom_name(485_926)).to eq('POM, MOIC')
    end
  end
end
