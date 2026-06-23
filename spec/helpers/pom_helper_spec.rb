require 'rails_helper'

RSpec.describe PomHelper do
  describe '#format_working_pattern' do
    it "formats a POM's FT working pattern" do
      expect(format_working_pattern(1.0)).to eq('Full time')
    end

    it "formats a POM's PT 0.0 working pattern" do
      expect(format_working_pattern(0.0)).to eq('Part time – 0 days per week')
    end

    it "formats a POM's PT 0.5 working pattern" do
      expect(format_working_pattern(0.5)).to eq('Part time – 2.5 days per week')
    end

    it "formats a POM's PT 0.8 working pattern" do
      expect(format_working_pattern(0.8)).to eq('Part time – 4 days per week')
    end
  end

  describe '#working_pattern_to_days' do
    it 'returns 0 days for pattern 0' do
      expect(working_pattern_to_days(0)).to eq('0 days')
    end

    it 'returns 0.5 day for pattern 1' do
      expect(working_pattern_to_days(1)).to eq('0.5 day')
    end

    it 'returns 2.5 days for pattern 5' do
      expect(working_pattern_to_days(5)).to eq('2.5 days')
    end

    it 'returns 4.5 days for pattern 9' do
      expect(working_pattern_to_days(9)).to eq('4.5 days')
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

    it "does not rename 'deleted' status" do
      pom = build(:pom, staffId: 2005,  status: 'deleted')
      expect(status(pom)).to eq('deleted')
    end
  end

  describe '#inactive_poms' do
    let(:active_pom) { double('PomWrapper', inactive?: false) }
    let(:unavailable_pom) { double('PomWrapper', inactive?: false) }
    let(:inactive_pom) { double('PomWrapper', inactive?: true) }
    let(:deleted_pom) { double('PomWrapper', inactive?: false) }
    let(:poms) { [active_pom, unavailable_pom, inactive_pom, deleted_pom] }

    it 'returns only inactive POMs' do
      expect(inactive_poms(poms)).to eq([inactive_pom])
    end

    it 'excludes deleted POMs' do
      expect(inactive_poms(poms)).not_to include(deleted_pom)
    end

    it 'excludes active and unavailable POMs' do
      expect(inactive_poms(poms)).not_to include(active_pom, unavailable_pom)
    end
  end
end
