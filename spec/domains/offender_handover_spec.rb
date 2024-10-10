require "rails_helper"

describe OffenderHandover do
  describe '#as_calculated_handover_date' do
    def responsibility_of(offender)
      described_class.new(offender).as_calculated_handover_date
    end

    def an_offender_who_is(**attributes)
      attributes_with_defaults = {
        indeterminate_sentence?: attributes.fetch(:isp, false),
        parole_outcome_not_release?: attributes.fetch(:parole_outcome_not_release, false),
        thd_12_or_more_months_from_now?: attributes.fetch(:thd_12_or_more_months_from_now, false),
        mappa_level: attributes.fetch(:mappa_level, nil),
        sentences: attributes.fetch(:sentences, double(sentenced_to_additional_future_isp?: false)),
        recalled?: attributes.fetch(:recalled, false),
        immigration_case?: attributes.fetch(:immigration_case, false),
        earliest_release_for_handover: attributes.fetch(:earliest_release_for_handover, NamedDate[1.day.ago, 'TED']),
        policy_case?: attributes.fetch(:policy_case, true),
        early_allocation?: attributes.fetch(:early_allocation, false),
        in_open_conditions?: attributes.fetch(:in_open_conditions, false),
        determinate_parole?: attributes.fetch(:determinate_parole, false),
        open_prison_rules_apply?: attributes.fetch(:open_prison_rules_apply, false),
        in_womens_prison?: attributes.fetch(:in_womens_prison, false),
        sentence_start_date: attributes.fetch(:sentence_start_date, double),
        category_active_since: attributes.fetch(:category_active_since, double),
        prison_arrival_date: attributes.fetch(:prison_arrival_date, double)
      }

      double(:mpc_offender, **attributes_with_defaults)
    end

    describe "responsibility overrides" do
      describe "an offender is COM responsible" do
        specify "if they have been recalled" do
          expect(responsibility_of an_offender_who_is(recalled: true))
            .to be_com_responsible.and have_no_handover_dates
        end

        specify "if they are an ISP who has been recalled and their THD is less than 12 months" do
          expect(responsibility_of an_offender_who_is(isp: true, recalled: true, thd_12_or_more_months_from_now: false))
            .to be_com_responsible.and have_no_handover_dates
        end

        specify 'if they are an immigration_case' do
          expect(responsibility_of an_offender_who_is(immigration_case: true))
            .to be_com_responsible.and have_no_handover_dates
        end

        specify 'if they not a policy case' do
          expect(responsibility_of an_offender_who_is(policy_case: false))
            .to be_com_responsible.and have_no_handover_dates
        end

        specify "if they are ISP and awaiting a parole decision" do
          expect(responsibility_of an_offender_who_is(isp: true, awaiting_parole_outcome: true))
            .to be_com_responsible.and have_handover_dates
        end

        specify "if they are ISP and the parole decision is to release" do
          expect(responsibility_of an_offender_who_is(isp: true, parole_outcome_release: true))
            .to be_com_responsible.and have_handover_dates
        end

        specify "if they are ISP and the parole decision is not to release and THD is less than 12 months from now" do
          expect(responsibility_of an_offender_who_is(
            isp: true,
            parole_outcome_release: false,
            parole_outcome_not_release: true,
            thd_12_or_more_months_from_now: false
          )).to be_com_responsible.and have_handover_dates
        end

        [2, 3].each do |mappa|
          specify "if they are ISP and the parole decision is not to release and THD is more than 12 months from now and they are mappa level #{mappa}" do
            expect(responsibility_of an_offender_who_is(
              isp: true,
              parole_outcome_release: false,
              parole_outcome_not_release: true,
              thd_12_or_more_months_from_now: true,
              mappa_level: mappa
            )).to be_com_responsible.and have_no_handover_dates
          end
        end
      end

      describe "an offender is POM responsible" do
        specify "if they are ISP with an additional ISP sentance" do
          responsibility = responsibility_of an_offender_who_is(
            isp: true,
            sentences: double(sentenced_to_additional_future_isp?: true)
          )
          expect(responsibility).to be_pom_responsible
          expect(responsibility).not_to be_com_supporting
          expect(responsibility).to have_no_handover_dates
        end

        specify 'if they have no earliest_release_for_handover' do
          responsibility = responsibility_of an_offender_who_is(earliest_release_for_handover: nil)
          expect(responsibility).to be_pom_responsible
          expect(responsibility).not_to be_com_supporting
          expect(responsibility).to have_no_handover_dates
        end
      end

      [nil, 0, 1].each do |mappa|
        specify "if they are an ISP who has been recalled and their THD is greater than 12 months from now and they are mappa level #{mappa}" do
          expect(responsibility_of an_offender_who_is(isp: true, recalled: true, thd_12_or_more_months_from_now: true, mappa_level: mappa))
            .to be_pom_responsible.and be_com_supporting.and have_no_handover_dates
        end
      end

      describe "an offender is POM responsible with COM supporting" do
        [nil, 0, 1].each do |mappa|
          specify "if they are ISP and the parole decision is not to release and THD is more than 12 months from now and they are mappa level #{mappa}" do
            expect(responsibility_of an_offender_who_is(
              isp: true,
              parole_outcome_release: false,
              parole_outcome_not_release: true,
              thd_12_or_more_months_from_now: true,
              mappa_level: mappa
            )).to be_pom_responsible.and be_com_supporting.and have_no_handover_dates
          end
        end
      end
    end

    context 'when none of the above' do
      it 'calculates the responsibility based on the handover dates' do
        offender = an_offender_who_is

        handover_date = Date.parse('25/12/2024')
        reason = 'reason_is_as_such'
        allow(Handover::HandoverCalculation).to receive(:calculate_handover_date).with(
          sentence_start_date: offender.sentence_start_date,
          earliest_release_date: offender.earliest_release_for_handover.date,
          is_early_allocation: offender.early_allocation?,
          is_indeterminate: offender.indeterminate_sentence?,
          in_open_conditions: offender.in_open_conditions?,
          is_determinate_parole: offender.determinate_parole?,
        ).and_return([handover_date, reason])

        start_date = Date.parse('01/01/2025')
        allow(Handover::HandoverCalculation).to receive(:calculate_handover_start_date).with(
          handover_date:,
          category_active_since_date: offender.category_active_since,
          prison_arrival_date: offender.prison_arrival_date,
          is_indeterminate: offender.indeterminate_sentence?,
          open_prison_rules_apply: offender.open_prison_rules_apply?,
          in_womens_prison: offender.in_womens_prison?,
        ).and_return(start_date)

        responsibility = 'responsibility_of_whom'
        allow(Handover::HandoverCalculation).to receive(:calculate_responsibility).with(
          handover_date:,
          handover_start_date: start_date
        ).and_return(responsibility)

        calculated_responsibility = responsibility_of offender
        expect(calculated_responsibility.responsibility).to eq(responsibility)
        expect(calculated_responsibility.handover_date).to eq(handover_date)
        expect(calculated_responsibility.start_date).to eq(start_date)
        expect(calculated_responsibility.reason).to eq(reason)
      end
    end
  end
end
