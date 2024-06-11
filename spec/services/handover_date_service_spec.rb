# frozen_string_literal: true

describe HandoverDateService, handover_calculations: true do
  context 'when April 2023 calculations' do
    let(:mpc_offender) do
      instance_double(MpcOffender, :mpc_offender,
                      offender_no: 'X1111XX',
                      inside_omic_policy?: true,
                      recalled?: false,
                      policy_case?: true,
                      immigration_case?: false,
                      sentence_start_date: double(:sentence_start_date),
                      early_allocation?: double(:early_allocation?),
                      indeterminate_sentence?: double(:indeterminate_sentence?),
                      in_open_conditions?: double(:in_open_conditions?),
                      category_active_since: double(:category_active_since),
                      prison_arrival_date: double(:prison_arrival_date),
                      open_prison_rules_apply?: double(:open_prison_rules_apply?),
                      in_womens_prison?: double(:in_womens_prison?),
                      determinate_parole?: double(:determinate_parole?),
                      earliest_release_for_handover: earliest_release,
                      target_hearing_date: double(:target_hearing_date),
                      tariff_date: double(:tariff_date),
                      parole_outcome_not_release?: false,
                      thd_12_or_more_months_from_now?: false,
                      mappa_level: [],
                      sentenced_to_an_additional_isp?: false)
    end
    let(:handover_date) { double :handover_date }
    let(:handover_start_date) { double :handover_start_date }
    let(:responsibility) { double :responsibility }
    let(:earliest_release) { double(:earliest_release, date: double(:earliest_release_date)) }

    before do
      allow(Handover::HandoverCalculation)
        .to receive_messages(calculate_handover_date: [handover_date, 'policy_reason'],
                             calculate_handover_start_date: handover_start_date,
                             calculate_responsibility: responsibility)

      expect(Handover::HandoverCalculation).not_to receive(:calculate_earliest_release)
    end

    context 'when offender is outside OMIC policy' do
      it 'raises an error' do
        allow(mpc_offender).to receive(:inside_omic_policy?).and_return(false)
        expect { described_class.handover(mpc_offender) }
          .to raise_error(RuntimeError, "Offender #{mpc_offender.offender_no} falls outside of OMIC policy - cannot calculate handover dates")
      end
    end

    context 'when not a policy case' do
      it 'raises error when outside OMIC policy' do
        allow(mpc_offender).to receive_messages(inside_omic_policy?: false)
        expect { described_class.handover(mpc_offender) }.to raise_error(/OMIC/)
      end

      it 'calculates no date and COM responsible for immigration cases' do
        allow(mpc_offender).to receive_messages(immigration_case?: true)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'immigration_case' })
      end

      it 'calculates no date and COM responsible when no release date' do
        allow(mpc_offender).to receive(:earliest_release_for_handover).and_return(nil)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::CUSTODY_ONLY,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'release_date_unknown' })
      end

      it 'calculates no date and COM responsible when pre-OMIC case' do
        allow(mpc_offender).to receive_messages(policy_case?: false)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'pre_omic_rules' })
      end
    end

    context 'when policy case' do
      subject!(:result) { described_class.handover(mpc_offender) } # Invoke immediately

      describe 'handover date' do
        it 'uses official calculations correctly' do
          expect(Handover::HandoverCalculation).to have_received(:calculate_handover_date).with(
            sentence_start_date: mpc_offender.sentence_start_date,
            earliest_release_date: earliest_release.date,
            is_early_allocation: mpc_offender.early_allocation?,
            is_indeterminate: mpc_offender.indeterminate_sentence?,
            in_open_conditions: mpc_offender.in_open_conditions?,
            is_determinate_parole: mpc_offender.determinate_parole?)
        end

        it 'returns results of official calculations' do
          expect(result.attributes).to include({ 'handover_date' => handover_date, 'reason' => 'policy_reason' })
        end
      end

      describe 'handover start date' do
        it 'uses official calculations correctly' do
          expect(Handover::HandoverCalculation).to have_received(:calculate_handover_start_date).with(
            handover_date: handover_date,
            category_active_since_date: mpc_offender.category_active_since,
            prison_arrival_date: mpc_offender.prison_arrival_date,
            is_indeterminate: mpc_offender.indeterminate_sentence?,
            open_prison_rules_apply: mpc_offender.open_prison_rules_apply?,
            in_womens_prison: mpc_offender.in_womens_prison?,
          ).at_least(1).time
        end

        it 'is set to the calculated value' do
          expect(result.start_date).to eq handover_start_date
        end
      end

      describe 'responsibility' do
        it 'is calculated using on the two calculated dates and today\'s date' do
          expect(Handover::HandoverCalculation).to have_received(:calculate_responsibility).with(
            handover_date: handover_date,
            handover_start_date: handover_start_date,
          )
        end

        it 'is set to the calculated value' do
          expect(result.responsibility).to eq responsibility.to_s
        end
      end
    end
  end
end
