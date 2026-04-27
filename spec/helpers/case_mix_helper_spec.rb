# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseMixHelper, type: :helper do
  let(:page) { Nokogiri::HTML(subject) }
  let(:tier_names) { CaseInformation.tier_levels }
  let(:tier_definitions) do
    tier_names.map do |tier|
      {
        name: tier,
        label: "Tier #{tier}",
        css_class: "case-mix__tier_#{tier.downcase}",
      }
    end
  end

  describe '#case_mix_key' do
    subject { helper.case_mix_key }

    it 'renders the key' do
      expect(page.css('.case-mix-key')).to be_present
      expect(page.css('.govuk-heading-s').text.strip).to eq 'Case mix by tier:'

      tier_definitions.each_with_index do |tier, index|
        li = page.css("li:nth-of-type(#{index + 1})")
        swatch = li.css(".case-mix-key__swatch.#{tier.fetch(:css_class)}")
        expect(li.text.strip).to eq tier.fetch(:label)
        expect(swatch).to be_present
      end
    end
  end

  describe '#case_mix_bar' do
    subject { helper.case_mix_bar_by_tiers(allocations) }

    let(:case_mix_bar) { page.css('.case-mix-bar') }

    let(:allocations) do
      tier_names.flat_map do |tier|
        1.upto(counts.fetch(tier)).map { |_i| double(tier: tier) }
      end
    end

    let(:counts) do
      tier_names.index_with { rand(1..15) }
    end

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

      tiers = tier_definitions.map do |tier|
        tier.merge(bar_class: tier.fetch(:css_class), count: counts.fetch(tier.fetch(:name)))
      end

      expect_rendered_tiers(tiers)
    end

    it 'sets the CSS variable "columns" to style the bar correctly' do
      expect_style = "--columns: #{counts.values.flat_map { |count| [0, "#{count}fr"] }.join(' ')};"
      expect(case_mix_bar.attr('style').value).to eq expect_style
    end

    context 'when some tier counts are zero' do
      let(:counts) do
        super().merge('C' => 0, 'D' => 0)
      end

      it 'excludes them from the case mix bar' do
        expect(page.text).not_to include 'Tier C'
        expect(page.text).not_to include 'Tier D'

        tiers = tier_definitions
          .reject { |tier| %w[C D].include?(tier.fetch(:name)) }
          .map { |tier| tier.merge(bar_class: tier.fetch(:css_class), count: counts.fetch(tier.fetch(:name))) }

        expect_rendered_tiers(tiers)
      end

      it 'sets the CSS variable "columns" to style the bar correctly' do
        filtered_counts = tier_names.filter_map { |tier| counts[tier] if counts[tier].positive? }
        expect_style = "--columns: #{filtered_counts.flat_map { |count| [0, "#{count}fr"] }.join(' ')};"
        expect(case_mix_bar.attr('style').value).to eq expect_style
      end
    end

    context 'when all tier counts are zero' do
      let(:counts) do
        tier_names.index_with { 0 }
      end

      it 'renders nothing' do
        expect(case_mix_bar).not_to be_present
        expect(page.text).to be_blank
      end
    end
  end

  context 'when new_tiers feature flag is enabled' do
    before { stub_feature_flag(:new_tiers, enabled: true) }

    describe '#case_mix_key' do
      subject { helper.case_mix_key }

      it 'renders keys for all tiers A-G' do
        %w[A B C D E F G].each do |tier|
          expect(page.text).to include "Tier #{tier}"
        end
      end
    end

    describe '#case_mix_bar_by_tiers' do
      subject { helper.case_mix_bar_by_tiers(allocations) }

      let(:allocations) do
        %w[A B C D E F G].flat_map { |tier| [double(tier: tier)] }
      end

      it 'includes extended tiers in the bar' do
        %w[E F G].each do |tier|
          expect(page.text).to include "Tier #{tier}"
        end
      end
    end
  end

  context 'when new_tiers feature flag is disabled' do
    before { stub_feature_flag(:new_tiers, enabled: false) }

    describe '#case_mix_key' do
      subject { helper.case_mix_key }

      it 'renders keys only for tiers A-D' do
        %w[A B C D].each do |tier|
          expect(page.text).to include "Tier #{tier}"
        end
        %w[E F G].each do |tier|
          expect(page.text).not_to include "Tier #{tier}"
        end
      end
    end
  end
end
