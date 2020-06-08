require 'rails_helper'

describe Nomis::Offender do
  describe '#handover_start_date' do
    context 'when in custody' do
      let(:offender) { build(:offender) }

      it 'has a value' do
        expect(offender.handover_start_date).not_to eq(nil)
      end
    end

    context 'when COM responsible already' do
      let(:offender) { build(:offender, sentence: Nomis::SentenceDetail.new) }

      it 'doesnt has a value' do
        expect(offender.handover_start_date).to eq(nil)
      end
    end
  end
end
