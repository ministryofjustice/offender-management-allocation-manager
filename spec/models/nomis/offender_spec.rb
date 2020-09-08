require 'rails_helper'

describe Nomis::Offender do
  describe '#handover_start_date' do
    context 'when in custody' do
      let(:offender) {
        build(:offender).tap { |o|
          o.sentence = Nomis::SentenceDetail.new(automatic_release_date: Time.zone.today + 1.year,
                                                 sentence_start_date: Time.zone.today)
          o.load_case_information(build(:case_information, case_allocation: 'NPS', mappa_level: 0))
        }
      }

      it 'has a value' do
        expect(offender.handover_start_date).not_to eq(nil)
      end
    end

    context 'when COM responsible already' do
      let(:offender) {
        build(:offender).tap { |o|
          o.sentence = Nomis::SentenceDetail.new
          o.load_case_information(build(:case_information))
        }
      }

      it 'doesnt has a value' do
        expect(offender.handover_start_date).to eq(nil)
      end
    end
  end
end
