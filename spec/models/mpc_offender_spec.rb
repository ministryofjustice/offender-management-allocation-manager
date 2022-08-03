require 'rails_helper'

RSpec.describe MpcOffender, type: :model do
  let(:case_information) { build(:case_information) }
  let(:prison) { build(:prison) }
  let(:db_offender) { build(:offender, nomis_offender_id: 'G1234GY', parole_records: [build(:parole_record, target_hearing_date: target_hearing_date)]) }
  let(:tariff_date) { Time.zone.today + 1.year }
  let(:parole_eligibility_date) { Time.zone.today + 2.years }
  let(:target_hearing_date) { nil }
  let(:prison_record) do
    build(:hmpps_api_offender,
          prisonerNumber: 'G1234GY',
          sentence: sentence)
  end
  let(:sentence) do
    attributes_for(:sentence_detail,
                   releaseDate: Time.zone.today + 10.years,
                   sentenceStartDate: Time.zone.today - 5.years,
                   tariffDate: tariff_date,
                   paroleEligibilityDate: parole_eligibility_date
                  )
  end
  let(:mpc_offender) do
    described_class.new(prison: prison,
                        offender: db_offender,
                        prison_record: prison_record)
  end

  describe '#next_parole_date' do
    context 'when target_hearing_date is unavailable' do
      context 'when tariff_date is earlier than parole_eligibility_date' do
        it 'returns tariff_date' do
          expect(mpc_offender.next_parole_date).to eq tariff_date
        end
      end

      context 'when parole_eligibility_date is earlier thhan tariff_date' do
        let(:parole_eligibility_date) { Time.zone.today - 1.year }

        it 'returns parole_eligibility_date' do
          expect(mpc_offender.next_parole_date).to eq parole_eligibility_date
        end
      end
    end

    context 'when target_hearing_date is available' do
      let(:target_hearing_date) { Time.zone.today + 5.years }

      it 'returns the target_hearing_date regardless of whether it is the earliest date' do
        expect(mpc_offender.next_parole_date).to eq target_hearing_date
      end
    end
  end

  describe '#next_parole_date_type' do
    context 'when next_parole_date is tariff_date' do
      it 'returns "TED"' do
        allow(mpc_offender).to receive(:next_parole_date).and_return(tariff_date)

        expect(mpc_offender.next_parole_date_type).to eq 'TED'
      end
    end

    context 'when next_parole_date is parole_eligibility_date' do
      it 'returns "TED"' do
        allow(mpc_offender).to receive(:next_parole_date).and_return(parole_eligibility_date)

        expect(mpc_offender.next_parole_date_type).to eq 'PED'
      end
    end

    context 'when next_parole_date is target_hearing_date' do
      it 'returns "TED"' do
        allow(mpc_offender).to receive(:next_parole_date).and_return(target_hearing_date)

        expect(mpc_offender.next_parole_date_type).to eq 'Target hearing date'
      end
    end
  end
end
