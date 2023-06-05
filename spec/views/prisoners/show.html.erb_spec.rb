# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "prisoners/show", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:case_info) { build(:case_information) }
  let(:prison) { build(:prison) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

  before do
    assign(:prison, prison)
    assign(:prisoner, offender)
    assign(:tasks, [])
    assign(:keyworker, build(:keyworker))
  end

  describe 'complexity badges' do
    let(:prison) { build(:womens_prison) }
    let(:api_offender) { build(:hmpps_api_offender, complexityLevel: complexity) }

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
      let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_a)) }

      it 'shows the category label' do
        expect(subject).to eq('Cat A')
      end
    end

    context "with a female category" do
      let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :female_closed)) }

      it 'shows the category label' do
        expect(subject).to eq('Female Closed')
      end
    end

    context 'when category is unknown' do
      # This happens when an offender's category assessment hasn't been completed yet
      let(:api_offender) { build(:hmpps_api_offender, category: nil) }

      it 'shows "Unknown"' do
        expect(subject).to eq('Unknown')
      end
    end
  end

  describe 'VLO section' do
    let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_a)) }

    context 'with no VLO in nDelius' do
      before { render }

      it 'has a stand-alone link to create a VLO' do
        expect(page).to have_content('Add new VLO contact')
      end
    end

    context 'with active VLO in nDelius' do
      let(:case_info) { build(:case_information, :with_active_vlo) }

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(page).not_to have_content('Victim liaison officer name')
        end

        it 'has a message containing a link to create a VLO' do
          expect(page).to have_css('a', text: 'add it to this service')
        end

        it 'has no stand-alone link to create a VLO' do
          expect(page).not_to have_content('Add new VLO contact')
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(page).to have_content('Victim liaison officer name')
        end

        it 'has no message containing a link to create a VLO' do
          expect(page).not_to have_css('a', text: 'add it to this service')
        end

        it 'has a stand-alone link to create a VLO' do
          expect(page).to have_content('Add new VLO contact')
        end
      end
    end
  end
end
