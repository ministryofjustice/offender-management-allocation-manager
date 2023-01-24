require 'rails_helper'

RSpec.describe MpcOffender, type: :model do
  subject(:offender) do
    build(:mpc_offender, prison: prison, prison_record: api_offender, offender: offender_model)
  end

  let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
  let(:offender_model) do
    instance_double(Offender,
                    id: nomis_offender_id,
                    nomis_offender_id: nomis_offender_id,
                    case_information: instance_double(CaseInformation))
  end
  let(:prison) { build(:prison) }
  let(:api_offender) { double(:nomis_offender, offender_no: nomis_offender_id) }

  describe '#additional_information' do
    let(:api_offender) { double(:nomis_offender, recalled?: recalled) }
    let(:recalled) { false }

    let(:prison_timeline) do
      { "prisonPeriod" => prison_periods }
    end

    before do
      allow(subject).to receive(:prison_timeline).and_return(prison_timeline)
    end

    context 'when never been in any prison before the current one' do
      let(:prison_periods) { [{ 'prisons' => [prison.code] }] }

      it 'New to custody' do
        expect(subject.additional_information).to eq(['New to custody'])
      end
    end

    context 'when been in prison before' do
      context 'when first time here' do
        let(:prison_periods) do
          [
            { 'prisons' => ['ABC', 'DEF'] },
            { 'prisons' => [prison.code] }
          ]
        end

        it 'New to this prison' do
          expect(subject.additional_information).to eq(['New to this prison'])
        end
      end

      context 'when returning to here' do
        let(:prison_periods) do
          [
            { 'prisons' => ['XYZ', prison.code] },
            { 'prisons' => ['ABC', 'DEF'] },
            { 'prisons' => [prison.code] }
          ]
        end

        it 'Returning to this prison' do
          expect(subject.additional_information).to eq(['Returning to this prison'])
        end
      end

      context 'when recalled to here' do
        let(:recalled) { true }

        context 'when first time here' do
          let(:prison_periods) do
            [
              { 'prisons' => ['ABC', 'DEF'] },
              { 'prisons' => [prison.code] }
            ]
          end

          it 'Recall - New to this prison' do
            expect(subject.additional_information).to eq(['Recall', 'New to this prison'])
          end
        end

        context 'when returning to here' do
          let(:prison_periods) do
            [
              { 'prisons' => ['XYZ', prison.code] },
              { 'prisons' => ['ABC', 'DEF'] },
              { 'prisons' => [prison.code] }
            ]
          end

          it 'Recall - Returning to this prison' do
            expect(subject.additional_information).to eq(['Recall', 'Returning to this prison'])
          end
        end

        # Although this doesn't make sense (an offender being recalled when they're new to custody),
        # it's been seen in data from the prison timeline API.
        #
        # We can only assume that either:
        #  1. The recalled flag (which comes from OffenderService.get_offender) has been set
        #     erroneously or not reset from previously (most likely), or
        #  2. The prison timeline is missing previous movements
        #
        # So this feature is a safeguard against conflicting data
        context 'when there are no previous prisons from API but recalled is true' do
          let(:prison_periods) do
            [{ 'prisons' => [prison.code] }]
          end

          it 'New to custody' do
            expect(subject.additional_information).to eq(['New to custody'])
          end
        end
      end
    end
  end

  describe '#rosh_summary' do
    before do
      stub_const('USE_RISKS_API', true)
      allow(OffenderService).to receive(:get_community_data).and_return({})

      allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_return(
        {
          "riskInCustody" => {
            "HIGH" => [
              "Know adult"
            ],
            "VERY_HIGH" => [
              "Staff",
              "Prisoners"
            ],
            "LOW" => [
              "Children",
              "Public"
            ]
          }
        }
      )
    end

    it 'returns correct level for each risk' do
      expect(subject.rosh_summary).to eq(
        {
          high_rosh_children: 'low',
          high_rosh_public: 'low',
          high_rosh_known_adult: 'high',
          high_rosh_staff: 'very high',
          high_rosh_prisoners: 'very high',
        }
      )
    end
  end

  describe '#active_alert_labels' do
    let(:api_result) do
      [
        { "alertCode" => "F1", "active" => true },
        { "alertCode" => "PEEP", "active" => true },
        { "alertCode" => "HA", "active" => false },
        { "alertCode" => "HA", "active" => false },
        { "alertCode" => "HA", "active" => false }
      ]
    end

    before do
      allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender_alerts).and_return(api_result)
    end

    it 'returns correct list' do
      expect(subject.active_alert_labels).to eq(["Veteran", "PEEP"])
    end
  end

  describe '#model' do
    it 'returns the Offender model instance' do
      expect(offender.model).to eq offender_model
    end
  end

  describe '#attributes_to_archive' do
    it 'works' do
      attrs = %w[
        recalled?
        immigration_case?
        indeterminate_sentence?
        sentenced?
        over_18?
        describe_sentence
        civil_sentence?
        sentence_start_date
        conditional_release_date
        automatic_release_date
        parole_eligibility_date
        tariff_date
        post_recall_release_date
        licence_expiry_date
        home_detention_curfew_actual_date
        home_detention_curfew_eligibility_date
        prison_arrival_date
        earliest_release_date
        earliest_release
        latest_temp_movement_date
        release_date
        date_of_birth
        main_offence
        awaiting_allocation_for
        location
        category_label
        complexity_level
        category_code
        category_active_since
        first_name
        last_name
        full_name_ordered
        full_name
        inside_omic_policy?
        offender_no
        prison_id
        restricted_patient?
        crn
        case_allocation
        manual_entry?
        nps_case?
        tier
        mappa_level
        welsh_offender
        ldu_email_address
        team_name
        ldu_name
        allocated_com_name
        allocated_com_email
        parole_review_date
        early_allocation_state
      ]

      attrs.each do |attr|
        allow(offender).to receive(attr).and_return(attr)
      end

      expected = attrs.index_with { |a| a }
      expect(offender.attributes_to_archive).to eq expected
    end
  end

  describe '#released?' do
    let(:today) { Date.new(2021, 1, 2) }

    it 'is false if release date is nil' do
      allow(subject).to receive_messages(earliest_release_date: nil)
      expect(subject.released?(relative_to_date: today)).to eq false
    end

    it 'is false if earliest release date is later than today' do
      allow(subject).to receive_messages(earliest_release_date: Date.new(2021, 1, 3))
      expect(subject.released?(relative_to_date: today)).to eq false
    end

    it 'is true if earliest release date is today'  do
      allow(subject).to receive_messages(earliest_release_date: today)
      expect(subject.released?(relative_to_date: today)).to eq true
    end

    it 'is true if earliest release date is earlier than today' do
      allow(subject).to receive_messages(earliest_release_date: Date.new(2021, 1, 1))
      expect(subject.released?(relative_to_date: today)).to eq true
    end
  end
end
