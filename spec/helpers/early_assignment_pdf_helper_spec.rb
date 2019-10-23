# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAssignmentPdfHelper, type: :helper do
  describe '#extremism_text_for' do
    context 'without extremism' do
      let(:ea) { build(:early_allocation) }

      it 'says no' do
        expect(helper.extremism_text_for(ea)).to eq('No')
      end
    end

    context 'when extremism and < 24 months' do
      let(:ea) { build(:early_allocation, extremism_separation: true, due_for_release_in_less_than_24months: true) }

      it 'says yes' do
        expect(helper.extremism_text_for(ea)).to eq('Yes - due for release in less than 24 months')
      end
    end

    context 'when extremism and > 24 months' do
      let(:ea) { build(:early_allocation, extremism_separation: true, due_for_release_in_less_than_24months: false) }

      it 'says yes' do
        expect(helper.extremism_text_for(ea)).to eq('Yes - not due for release until more than 24 months')
      end
    end
  end
end
