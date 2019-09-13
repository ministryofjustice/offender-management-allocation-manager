require 'rails_helper'

RSpec.describe PomHelper do
  describe 'format_working_pattern' do
    it "formats a POM's working pattern" do
      expect(format_working_pattern(1.0)).to eq('Full time')
    end
  end
end
