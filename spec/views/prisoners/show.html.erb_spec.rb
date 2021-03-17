# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "prisoners/show", type: :view do
  describe 'complexity badges' do
    let(:prison) { build(:womens_prison) }
    let(:page) { Nokogiri::HTML(rendered) }
    let(:offender) { build(:offender, complexityLevel: complexity).tap { |offender| offender.load_case_information(case_info) } }
    let(:case_info) { create(:case_information) }
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      test_strategy.switch!(:womens_estate, true)
      assign(:prison, prison)
      assign(:prisoner, offender)
      assign(:tasks, [])
      assign(:keyworker, build(:keyworker))
      assign(:case_info, case_info)
      render
    end

    after do
      test_strategy.switch!(:womens_estate, false)
    end

    context 'with low complexity' do
      let(:complexity) { 'low' }

      it 'shows low complexity badge' do
        expect(page).to have_content 'LOW COMPLEXITY'
      end
    end

    context 'with medium complexity' do
      let(:complexity) { 'medium' }

      it 'shows medium complexity badge' do
        expect(page).to have_content 'MEDIUM COMPLEXITY'
      end
    end

    context 'with high complexity' do
      let(:complexity) { 'high' }

      it 'shows high complexity badge' do
        expect(page).to have_content 'HIGH COMPLEXITY'
      end
    end
  end
end
