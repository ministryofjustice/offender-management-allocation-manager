# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "prisoners/show", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:case_info) { build(:case_information) }
  let(:prison) { build(:prison) }

  before do
    offender.load_case_information(case_info)
    assign(:prison, prison)
    assign(:prisoner, offender)
    assign(:tasks, [])
    assign(:keyworker, build(:keyworker))
    assign(:case_info, case_info)
  end

  describe 'complexity badges' do
    let(:prison) { build(:womens_prison) }
    let(:offender) { build(:offender, complexityLevel: complexity) }
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      render
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

  describe 'offender category' do
    subject { page.css('#category-code').text }

    before { render }

    context "with a male category" do
      let(:offender) { build(:offender, category: build(:offender_category, :cat_a)) }

      it 'shows the category label' do
        expect(subject).to eq('Cat A')
      end
    end

    context "with a female category" do
      let(:offender) { build(:offender, category: build(:offender_category, :female_closed)) }

      it 'shows the category label' do
        expect(subject).to eq('Female Closed')
      end
    end

    context 'when category is unknown' do
      # This happens when an offender's category assessment hasn't been completed yet
      let(:offender) { build(:offender, category: nil) }

      it 'shows "Unknown"' do
        expect(subject).to eq('Unknown')
      end
    end
  end
end
