# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseMixHelper, type: :helper do
  let(:page) { Nokogiri::HTML(subject) }

  describe '#case_mix_key' do
    subject { helper.case_mix_key }

    it 'renders the key' do
      expect(page.css('.case-mix-key')).to be_present
      expect(page.css('.govuk-heading-s').text.strip).to eq 'Case mix by tier'

      tiers = [
        { label: 'Tier A', swatch_class: 'case-mix__tier_a' },
        { label: 'Tier B', swatch_class: 'case-mix__tier_b' },
        { label: 'Tier C', swatch_class: 'case-mix__tier_c' },
        { label: 'Tier D', swatch_class: 'case-mix__tier_d' },
        { label: 'Tier N/A', swatch_class: 'case-mix__tier_na' },
      ]

      tiers.each_with_index do |tier, index|
        li = page.css("li:nth-of-type(#{index + 1})")
        swatch = li.css(".case-mix-key__swatch.#{tier.fetch(:swatch_class)}")
        expect(li.text.strip).to eq tier.fetch(:label)
        expect(swatch).to be_present
      end
    end
  end

  describe '#case_mix_bar' do
    subject { helper.case_mix_bar_by_tiers(pom) }

    let(:case_mix_bar) { page.css('.case-mix-bar') }

    let(:pom) {
      double(allocations: 1.upto(tier_a_count).map { |_i| double(tier: 'A') } +
                          1.upto(tier_b_count).map { |_i| double(tier: 'B') } +
                          1.upto(tier_c_count).map { |_i| double(tier: 'C') } +
                          1.upto(tier_d_count).map { |_i| double(tier: 'D') } +
                          1.upto(tier_na_count).map { |_i| double(tier: 'N/A') }
                      )
    }

    # Randomise tier counts
    let(:tier_a_count) { rand(1..15) }
    let(:tier_b_count) { rand(1..15) }
    let(:tier_c_count) { rand(1..15) }
    let(:tier_d_count) { rand(1..15) }
    let(:tier_na_count) { rand(1..15) }

    def expect_rendered_tiers(tiers)
      tiers.each_with_index do |tier, index|
        dt = page.css("dt:nth-of-type(#{index + 1})")
        dd = page.css("dd:nth-of-type(#{index + 1})")

        expect(dt.text.strip).to eq tier.fetch(:label)
        expect(dd.attr('title').value).to eq tier.fetch(:label)
        expect(dd.css(".#{tier.fetch(:bar_class)}")).to be_present
      end
    end

    it 'renders the case mix bar' do
      expect(case_mix_bar).to be_present

      tiers = [
        { label: 'Tier A', bar_class: 'case-mix__tier_a', count: tier_a_count },
        { label: 'Tier B', bar_class: 'case-mix__tier_b', count: tier_b_count },
        { label: 'Tier C', bar_class: 'case-mix__tier_c', count: tier_c_count },
        { label: 'Tier D', bar_class: 'case-mix__tier_d', count: tier_d_count },
        { label: 'Tier N/A', bar_class: 'case-mix__tier_na', count: tier_na_count },
      ]

      expect_rendered_tiers(tiers)
    end

    it 'sets the CSS variable "columns" to style the bar correctly' do
      expect_style = "--columns: 0 #{tier_a_count}fr 0 #{tier_b_count}fr 0 #{tier_c_count}fr 0 #{tier_d_count}fr 0 #{tier_na_count}fr;"
      expect(case_mix_bar.attr('style').value).to eq expect_style
    end

    context 'when some tier counts are zero' do
      let(:tier_c_count) { 0 }
      let(:tier_d_count) { 0 }

      it 'excludes them from the case mix bar' do
        expect(page.text).not_to include 'Tier C'
        expect(page.text).not_to include 'Tier D'

        tiers = [
          { label: 'Tier A', bar_class: 'case-mix__tier_a', count: tier_a_count },
          { label: 'Tier B', bar_class: 'case-mix__tier_b', count: tier_b_count },
          { label: 'Tier N/A', bar_class: 'case-mix__tier_na', count: tier_na_count },
        ]

        expect_rendered_tiers(tiers)
      end

      it 'sets the CSS variable "columns" to style the bar correctly' do
        expect_style = "--columns: 0 #{tier_a_count}fr 0 #{tier_b_count}fr 0 #{tier_na_count}fr;"
        expect(case_mix_bar.attr('style').value).to eq expect_style
      end
    end

    context 'when all tier counts are zero' do
      let(:tier_a_count) { 0 }
      let(:tier_b_count) { 0 }
      let(:tier_c_count) { 0 }
      let(:tier_d_count) { 0 }
      let(:tier_na_count) { 0 }

      it 'renders nothing' do
        expect(case_mix_bar).not_to be_present
        expect(page.text).to be_blank
      end
    end
  end
end
