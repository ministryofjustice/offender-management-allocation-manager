# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "handovers/index", type: :view do
  before do
    assign(:prison, build(:prison))
    assign(:staff_id, pom.staff_id)
    assign(:summary, double(handovers_total: 0))
    assign(:offenders,
           Kaminari::paginate_array([]).page(1))
    assign(:is_spo, is_spo)
    assign(:is_pom, is_pom)
    render
  end

  let(:pom) { build(:pom) }
  let(:page) { Nokogiri::HTML(rendered) }

  context 'when spo' do
    let(:is_spo) { true }
    let(:is_pom) { false }

    it 'shows only 1 subnav item' do
      expect(page.css('.moj-sub-navigation__item').size).to eq(1)
      expect(page).to have_content 'See all handover cases'
    end
  end

  context 'when pom' do
    let(:is_spo) { false }
    let(:is_pom) { true }

    it 'shows only 1 subnav item' do
      expect(page.css('.moj-sub-navigation__item').size).to eq(1)
      expect(page).to have_content 'See handover cases that you are allocated'
    end
  end

  context 'when pom and spo' do
    let(:is_spo) { true }
    let(:is_pom) { true }

    it 'shows both subnav items' do
      expect(page.css('.moj-sub-navigation__item').size).to eq(2)
      expect(page).to have_content 'See handover cases that you are allocated'
      expect(page).to have_content 'See all handover cases'
    end
  end
end
