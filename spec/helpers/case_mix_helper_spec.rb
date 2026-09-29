# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseMixHelper, type: :helper do
  let(:page) { Nokogiri::HTML(subject) }
  let(:tier_names) { CaseInformation.tier_levels }

  def allocations_for(counts)
    tier_names.flat_map do |tier|
      Array.new(counts.fetch(tier)) { double(tier:) }
    end
  end

  def expect_rendered_tiers(tiers)
    tiers.each_with_index do |tier, index|
      dt = page.css("dt:nth-of-type(#{index + 1})")
      dd = page.css("dd:nth-of-type(#{index + 1})")

      expect(dt.text.strip).to eq "Tier #{tier}"
      expect(dd.attr('title').value).to eq "Tier #{tier}"
      expect(dd.css(".case-mix__tier_#{tier.downcase}")).to be_present
    end
  end

  describe '#case_mix_key' do
    subject { helper.case_mix_key }

    it 'renders keys for all tiers' do
      expect(page.css('.case-mix-key')).to be_present
      expect(page.css('.govuk-heading-s').text.strip).to eq 'Case mix by tier:'

      tier_names.each do |tier|
        expect(page.text).to include "Tier #{tier}"
      end
    end
  end

  describe '#case_mix_bar' do
    subject { helper.case_mix_bar_by_tiers(allocations) }

    let(:counts) { tier_names.each_with_index.to_h { |tier, index| [tier, index + 1] } }
    let(:allocations) { allocations_for(counts) }

    it 'renders the case mix bar' do
      expect(page.css('.case-mix-bar')).to be_present

      expect_rendered_tiers(tier_names)
    end

    it 'sets the CSS variable "columns" to style the bar correctly' do
      expect_style = "--columns: #{counts.values.flat_map { |count| [0, "#{count}fr"] }.join(' ')};"
      expect(page.css('.case-mix-bar').attr('style').value).to eq expect_style
    end

    context 'when some tier counts are zero' do
      let(:counts) { super().merge('C' => 0, 'D' => 0) }

      it 'excludes them from the case mix bar' do
        expect(page.text).not_to include 'Tier C'
        expect(page.text).not_to include 'Tier D'

        expect_rendered_tiers(tier_names - %w[C D])
      end

      it 'sets the CSS variable "columns" to style the bar correctly' do
        filtered_counts = tier_names.filter_map { |tier| counts[tier] if counts[tier].positive? }
        expect_style = "--columns: #{filtered_counts.flat_map { |count| [0, "#{count}fr"] }.join(' ')};"
        expect(page.css('.case-mix-bar').attr('style').value).to eq expect_style
      end
    end

    context 'when all tier counts are zero' do
      let(:counts) { tier_names.index_with { 0 } }

      it 'renders nothing' do
        expect(page.css('.case-mix-bar')).not_to be_present
        expect(page.text).to be_blank
      end
    end
  end
end
