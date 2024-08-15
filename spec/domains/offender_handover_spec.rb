require "rails_helper"

describe OffenderHandover do
  describe '#as_calculated_handover_date' do
    subject(:responsibility) { described_class.new(offender).as_calculated_handover_date }

    let(:indeterminate_sentence) { false }
    let(:parole_outcome_not_release) { false }
    let(:thd_12_or_more_months_from_now) { false }
    let(:mappa_level) { false }
    let(:sentences) { double('sentences').as_null_object }
    let(:recalled) { false }
    let(:immigration_case) { false }
    let(:earliest_release_for_handover) { NamedDate[1.day.ago, 'TED'] }
    let(:policy_case) { true }
    let(:early_allocation) { false }
    let(:in_open_conditions) { false }
    let(:determinate_parole) { false }
    let(:open_prison_rules_apply) { false }
    let(:in_womens_prison) { false }
    let(:sentence_start_date) { double }
    let(:category_active_since) { double }
    let(:prison_arrival_date) { double }

    let(:offender) do
      double(:offender,
             indeterminate_sentence?: indeterminate_sentence,
             parole_outcome_not_release?: parole_outcome_not_release,
             thd_12_or_more_months_from_now?: thd_12_or_more_months_from_now,
             mappa_level: mappa_level,
             sentences: sentences,
             recalled?: recalled,
             immigration_case?: immigration_case,
             earliest_release_for_handover: earliest_release_for_handover,
             policy_case?: policy_case,
             early_allocation?: early_allocation,
             in_open_conditions?: in_open_conditions,
             determinate_parole?: determinate_parole,
             open_prison_rules_apply?: open_prison_rules_apply,
             in_womens_prison?: in_womens_prison,
             sentence_start_date: sentence_start_date,
             category_active_since: category_active_since,
             prison_arrival_date: prison_arrival_date
            )
    end

    before { stub_const('USE_PPUD_PAROLE_DATA', true) }

    context 'when offender is an ISP' do
      let(:indeterminate_sentence) { true }

      context 'when Parole outcome is not release, THD is 12 months from now' do
        let(:parole_outcome_not_release) { true }
        let(:thd_12_or_more_months_from_now) { true }

        context 'when mappa is either 2 or 3' do
          [2, 3].each do |mappa|
            let(:mappa_level) { mappa }

            it 'is COM responsible as parole_mappa_2_3' do
              expect(subject).to be_com_responsible
              expect(subject.reason).to eq('parole_mappa_2_3')
            end
          end
        end

        context 'when mappa is empty or 1' do
          [nil, 1].each do |mappa|
            let(:mappa_level) { mappa }

            it 'is POM responsible with COM supporting as thd_over_12_months' do
              expect(subject).to be_pom_responsible
              expect(subject).to be_com_supporting
              expect(subject.reason).to eq('thd_over_12_months')
            end
          end
        end
      end

      context 'when offender is sentenced to an additional ISP' do
        let(:sentences) { double(multiple_indeterminate_sentences?: true) }

        it 'is POM responsible as additional_isp' do
          expect(subject).to be_pom_responsible
          expect(subject.reason).to eq('additional_isp')
        end
      end
    end

    context 'when offender is recalled' do
      let(:recalled) { true }

      it 'is COM responsible as recall_case' do
        expect(subject).to be_com_responsible
        expect(subject.reason).to eq('recall_case')
      end
    end

    context 'when offender is immigration_case' do
      let(:immigration_case) { true }

      it 'is COM responsible as immigration_case' do
        expect(subject).to be_com_responsible
        expect(subject.reason).to eq('immigration_case')
      end
    end

    context 'when there is no earliest_release_for_handover' do
      let(:earliest_release_for_handover) { nil }

      it 'is POM responsible as release_date_unknown' do
        expect(subject).to be_pom_responsible
        expect(subject).not_to be_com_supporting
        expect(subject.reason).to eq('release_date_unknown')
      end
    end

    context 'when the offender is not a policy case' do
      let(:policy_case) { false }

      it 'is COM responsible as pre_omic_rules' do
        expect(subject).to be_com_responsible
        expect(subject.reason).to eq('pre_omic_rules')
      end
    end

    context 'when none of the above' do
      it 'calculates the responsibility based on the handover dates' do
        handover_date = Date.parse('25/12/2024')
        reason = 'reason_is_as_such'
        allow(Handover::HandoverCalculation).to receive(:calculate_handover_date).with(
          sentence_start_date:,
          earliest_release_date: earliest_release_for_handover.date,
          is_early_allocation: early_allocation,
          is_indeterminate: indeterminate_sentence,
          in_open_conditions:,
          is_determinate_parole: determinate_parole,
        ).and_return([handover_date, reason])

        start_date = Date.parse('01/01/2025')
        allow(Handover::HandoverCalculation).to receive(:calculate_handover_start_date).with(
          handover_date:,
          category_active_since_date: category_active_since,
          prison_arrival_date:,
          is_indeterminate: indeterminate_sentence,
          open_prison_rules_apply:,
          in_womens_prison:,
        ).and_return(start_date)

        responsibility = 'responsibility_of_whom'
        allow(Handover::HandoverCalculation).to receive(:calculate_responsibility).with(
          handover_date:,
          handover_start_date: start_date
        ).and_return(responsibility)

        expect(subject.responsibility).to eq(responsibility)
        expect(subject.handover_date).to eq(handover_date)
        expect(subject.start_date).to eq(start_date)
        expect(subject.reason).to eq(reason)
      end
    end
  end
end
