# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BadgeHelper, type: :helper do
  context 'when determinate' do
    let(:offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate)) }

    it 'is blue' do
      expect(helper.badge_colour(offender)).to eq 'blue'
    end

    it 'displays determinant' do
      expect(helper.badge_text(offender)).to eq 'Determinate'
    end
  end

  context 'when indeterminate' do
    let(:offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate)) }

    it 'is purple' do
      expect(helper.badge_colour(offender)).to eq 'purple'
    end

    it 'displays indeterminate' do
      expect(helper.badge_text(offender)).to eq 'Indeterminate'
    end
  end
end
