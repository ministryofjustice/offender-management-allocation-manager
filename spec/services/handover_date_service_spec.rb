# frozen_string_literal: true

describe HandoverDateService do
  context 'when using PPUD dates' do
    subject(:responsibility) { described_class.handover(mpc_offender) }

    let(:today) { Date.parse('01/02/2024') }
    let(:tariff_date) { today + 24.months }
    let(:mpc_offender) { build_mpc_offender }
    let(:parole_reviews) { [] }
    let(:sentence_type) { :determinate }
    let(:mappa_level) { nil }

    def build_mpc_offender
      db_offender = create(:offender, case_information: build(:case_information, mappa_level:), parole_reviews:)

      api_offender = build(:hmpps_api_offender,
                           prisonerNumber: db_offender.nomis_offender_id,
                           prisonId: 'LEI',
                           category: build(:offender_category, :cat_c),
                           sentence: attributes_for(:sentence_detail, sentence_type, tariffDate: tariff_date, sentenceStartDate: '1/1/2018')
                          )

      MpcOffender.new(prison: 'LEI', offender: db_offender, prison_record: api_offender)
    end

    before { stub_const('USE_PPUD_PAROLE_DATA', true) }
    before { allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender_sentences_and_offences).and_return([]) }

    context "when it is within 12 months before TED (Tariff End Date)" do
      let(:tariff_date) { today + 11.months }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "when it is within 12 months before THD (Target Hearing Date) which has come from PPUD" do
      let(:parole_reviews) { [build(:parole_review, target_hearing_date: today + 11.months, hearing_outcome_received_on: Time.zone.today, hearing_outcome: 'Anything')] }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context "when it is within 12 months before THD (Target Hearing Date) which has been manually entered" do
      before { create(:parole_record, nomis_offender_id: mpc_offender.nomis_offender_id, parole_review_date: today + 11.months) }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context 'when it is after TED and no parole decision has been made' do
      let(:parole_reviews) { [build(:parole_review, target_hearing_date: today + 24.months)] }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context 'when a parole decision of Release has been made' do
      let(:parole_reviews) { [build(:parole_review, target_hearing_date: today - 1.day, hearing_outcome_received_on: Time.zone.today, hearing_outcome: 'Release [*]')] }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context 'when a parole decision of Not Release has been made' do
      context 'and THD is within 12 months of now' do
        let(:parole_reviews) { [build(:parole_review, target_hearing_date: today + 11.months, hearing_outcome_received_on: Time.zone.today, hearing_outcome: 'Anything But Release')] }

        specify "COM is responsible" do
          expect(responsibility).to be_com_responsible
        end
      end

      context 'and THD is more than 12 months of now' do
        let(:parole_reviews) { [build(:parole_review, target_hearing_date: today + 24.months, hearing_outcome_received_on: Time.zone.today, hearing_outcome: 'Anything But Release')] }

        {
          nil => :be_pom_responsible,
          1 => :be_pom_responsible,
          2 => :be_com_responsible,
          3 => :be_com_responsible
        }.each do |mappa_level, responsibility_expectation|
          context "and MAPPA level is #{mappa_level}" do
            let(:mappa_level) { mappa_level }

            it { is_expected.to send(responsibility_expectation) }
          end
        end
      end
    end

    context 'when recalled on initial ISP sentence' do
      let(:sentence_type) { :indeterminate_recall }

      specify "COM is responsible" do
        expect(responsibility).to be_com_responsible
      end
    end

    context 'when offender has an additional ISP sentence' do
      before { allow(mpc_offender).to receive(:sentenced_to_an_additional_isp?).and_return(true) }

      specify "only the POM is responsible" do
        expect(responsibility).to be_pom_responsible
        expect(responsibility).not_to be_com_supporting
      end
    end
  end

  context 'when April 2023 calculations' do
    let(:mpc_offender) do
      instance_double(MpcOffender, :mpc_offender,
                      offender_no: 'X1111XX',
                      inside_omic_policy?: true,
                      recalled?: false).as_null_object
    end
    let(:offender_wrapper) do
      instance_double described_class::OffenderWrapper, :offender_wrapper,
                      policy_case?: true, recalled?: false, immigration_case?: false,
                      sentence_start_date: double(:sentence_start_date),
                      early_allocation?: double(:early_allocation?),
                      indeterminate_sentence?: double(:indeterminate_sentence?),
                      in_open_conditions?: double(:in_open_conditions?),
                      category_active_since: double(:category_active_since),
                      prison_arrival_date: double(:prison_arrival_date),
                      open_prison_rules_apply?: double(:open_prison_rules_apply?),
                      in_womens_prison?: double(:in_womens_prison?),
                      determinate_parole?: double(:determinate_parole?),
                      earliest_release: earliest_release
    end
    let(:handover_date) { double :handover_date }
    let(:handover_start_date) { double :handover_start_date }
    let(:responsibility) { double :responsibility }
    let(:earliest_release) { double(:earliest_release, date: double(:earliest_release_date)) }

    before do
      allow(described_class::OffenderWrapper).to receive(:new).with(mpc_offender)
                                                              .and_return(offender_wrapper)
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

      it 'calculates no date and COM responsible for recall cases' do
        allow(mpc_offender).to receive_messages(recalled?: true)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'recall_case' })
      end

      it 'calculates no date and COM responsible for immigration cases' do
        allow(offender_wrapper).to receive_messages(immigration_case?: true)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'immigration_case' })
      end

      it 'calculates no date and COM responsible when no release date' do
        allow(offender_wrapper).to receive(:earliest_release).and_return(nil)

        expect(described_class.handover(mpc_offender).attributes)
          .to include({ 'responsibility' => CalculatedHandoverDate::CUSTODY_ONLY,
                        'start_date' => nil,
                        'handover_date' => nil,
                        'reason' => 'release_date_unknown' })
      end

      it 'calculates no date and COM responsible when pre-OMIC case' do
        allow(offender_wrapper).to receive_messages(policy_case?: false)

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
            sentence_start_date: offender_wrapper.sentence_start_date,
            earliest_release_date: earliest_release.date,
            is_early_allocation: offender_wrapper.early_allocation?,
            is_indeterminate: offender_wrapper.indeterminate_sentence?,
            in_open_conditions: offender_wrapper.in_open_conditions?,
            is_determinate_parole: offender_wrapper.determinate_parole?)
        end

        it 'returns results of official calculations' do
          expect(result.attributes).to include({ 'handover_date' => handover_date, 'reason' => 'policy_reason' })
        end
      end

      describe 'handover start date' do
        it 'uses official calculations correctly' do
          expect(Handover::HandoverCalculation).to have_received(:calculate_handover_start_date).with(
            handover_date: handover_date,
            category_active_since_date: offender_wrapper.category_active_since,
            prison_arrival_date: offender_wrapper.prison_arrival_date,
            is_indeterminate: offender_wrapper.indeterminate_sentence?,
            open_prison_rules_apply: offender_wrapper.open_prison_rules_apply?,
            in_womens_prison: offender_wrapper.in_womens_prison?,
          )
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
