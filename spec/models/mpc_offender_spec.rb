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

  describe 'parole-related methods' do
    let(:completed_parole_record_1_date) { Time.zone.today - 2.years }
    let(:completed_parole_record_2_thd) { Time.zone.today - 1.day }
    let(:completed_parole_record_2_outcome_date) { Time.zone.today }
    let(:completed_parole_record_1) { create(:parole_record, custody_report_due: completed_parole_record_1_date, target_hearing_date: completed_parole_record_1_date, hearing_outcome: 'Stay In Closed [*]', hearing_outcome_received: completed_parole_record_1_date) }
    let(:completed_parole_record_2) { create(:parole_record, custody_report_due: Time.zone.today - 1.day, target_hearing_date: completed_parole_record_2_thd, hearing_outcome: 'Stay In Closed [*]', hearing_outcome_received: completed_parole_record_2_outcome_date) }

    context 'when the offender has an upcoming parole hearing' do
      let(:incomplete_parole_record_thd) { Time.zone.today + 2.years }
      let(:incomplete_parole_record) { create(:parole_record, custody_report_due: Time.zone.today + 2.years, target_hearing_date: incomplete_parole_record_thd) }
      let(:db_offender) { create(:offender, nomis_offender_id: 'G1234GY', parole_records: [completed_parole_record_1, completed_parole_record_2, incomplete_parole_record]) }

      describe '#next_thd' do
        it 'returns the target hearing date of the incomplete parole record' do
          expect(mpc_offender.next_thd).to eq(incomplete_parole_record_thd)
        end
      end

      describe '#target_hearing_date' do
        it 'returns the target hearing date of the incomplete parole record' do
          expect(mpc_offender.target_hearing_date).to eq(incomplete_parole_record_thd)
        end
      end

      describe '#hearing_outcome_received' do
        it 'returns nil' do
          expect(mpc_offender.hearing_outcome_received).to eq(nil)
        end
      end

      describe '#last_hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(mpc_offender.last_hearing_outcome_received).to eq(completed_parole_record_2_outcome_date)
        end
      end
    end

    context 'when the offender does not have an upcoming parole hearing' do
      let(:db_offender) { create(:offender, nomis_offender_id: 'G1234GY', parole_records: [completed_parole_record_1, completed_parole_record_2]) }

      describe '#next_thd' do
        it 'returns nil' do
          expect(mpc_offender.next_thd).to eq(nil)
        end
      end

      describe '#target_hearing_date' do
        it 'returns the target hearing date of the most recent completed parole record' do
          expect(mpc_offender.target_hearing_date).to eq(completed_parole_record_2_thd)
        end
      end

      describe '#hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(mpc_offender.hearing_outcome_received).to eq(completed_parole_record_2_outcome_date)
        end
      end

      describe '#last_hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(mpc_offender.last_hearing_outcome_received).to eq(completed_parole_record_2_outcome_date)
        end
      end
    end
  end
end
