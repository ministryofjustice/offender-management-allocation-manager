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

    it "renames 'inactive' status to away from work" do
      pom = build(:pom, staffId: 2005,  status: 'inactive')
      expect(status(pom)).to eq('away from work')
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

  describe '#sortable_grade' do
    let(:prison_pom) { double('POM', position_description: 'Prison Officer', position: RecommendationService::PRISON_POM) }
    let(:probation_pom) { double('POM', position_description: 'Probation Officer', position: RecommendationService::PROBATION_POM) }

    context 'when there is no recommendation' do
      it 'returns the plain grade' do
        expect(sortable_grade(prison_pom, nil)).to eq('Prison POM')
        expect(sortable_grade(probation_pom, nil)).to eq('Probation POM')
      end
    end

    context 'when prison POM is recommended' do
      let(:recommended_pom_type) { RecommendationService::PRISON_POM }

      it 'prefixes 0 for matching POMs' do
        expect(sortable_grade(prison_pom, recommended_pom_type)).to eq('0 Prison POM')
      end

      it 'prefixes 1 for non-matching POMs' do
        expect(sortable_grade(probation_pom, recommended_pom_type)).to eq('1 Probation POM')
      end
    end

    context 'when probation POM is recommended' do
      let(:recommended_pom_type) { RecommendationService::PROBATION_POM }

      it 'prefixes 0 for matching POMs' do
        expect(sortable_grade(probation_pom, recommended_pom_type)).to eq('0 Probation POM')
      end

      it 'prefixes 1 for non-matching POMs' do
        expect(sortable_grade(prison_pom, recommended_pom_type)).to eq('1 Prison POM')
      end
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

  describe '#pom_staff_list_tab_path' do
    it 'returns the inactive POMs tab for a non-limbo POM' do
      pom = double('POM', in_limbo?: false)
      expect(pom_staff_list_tab_path(pom, 'LEI')).to eq(prison_poms_path('LEI', anchor: 'inactive_poms!top'))
    end

    it 'returns the attention needed tab for a limbo POM' do
      pom = double('POM', in_limbo?: true)
      expect(pom_staff_list_tab_path(pom, 'LEI')).to eq(prison_poms_path('LEI', anchor: 'attention_needed!top'))
    end
  end
end
