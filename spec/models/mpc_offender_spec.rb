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
                    case_information: instance_double(CaseInformation),
                    parole_records: [parole_record, completed_parole_record])
  end
  let(:prison) { build(:prison) }
  let(:api_offender) { 
    double(:nomis_offender, 
            offender_no: nomis_offender_id, 
            release_date: Time.zone.today + 10.years, 
            sentence_start_date: Time.zone.today - 5.years, 
            tariff_date: tariff_date, 
            parole_eligibility_date: parole_eligibility_date,
            recalled?: recalled) 
  }
  let(:tariff_date) { Time.zone.today + 1.year }
  let(:parole_eligibility_date) { Time.zone.today + 2.years }
  let(:target_hearing_date) { nil }
  let(:parole_record) { build(:parole_record, target_hearing_date: target_hearing_date) }
  let(:completed_parole_record) { build(:parole_record, target_hearing_date: Time.zone.today - 1.year, review_status: 'Inactive', hearing_outcome: 'Stay in Closed', hearing_outcome_received: Time.zone.today - 11.months)}
  let(:recalled) { false }

  before do
    allow(offender_model).to receive(:most_recent_parole_record).and_return(parole_record)
    allow(offender_model).to receive(:parole_record_awaiting_hearing).and_return(parole_record)
    allow(offender_model).to receive(:most_recent_completed_parole_record).and_return(completed_parole_record)
    allow(offender_model).to receive(:build_parole_record_sections)
    allow(offender_model).to receive(:early_allocations).and_return(Offender.none)
  end

  describe '#additional_information' do
    

    let(:prison_timeline) do
      { "prisonPeriod" => prison_periods }
    end

    before do
      allow(subject).to receive(:prison_timeline).and_return(prison_timeline)
    end

    context 'when prison_timeline returns nil (e.g. when API returns 500)' do
      let(:prison_timeline) { nil }

      it 'returns empty array' do
        expect(subject.additional_information).to eq([])
      end
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
        target_hearing_date
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

  describe 'parole-related methods' do
    describe '#next_parole_date' do
      context 'when target_hearing_date is unavailable' do
        context 'when tariff_date is earlier than parole_eligibility_date' do
          it 'returns tariff_date' do
            expect(subject.next_parole_date).to eq tariff_date
          end
        end
  
        context 'when parole_eligibility_date is earlier thhan tariff_date' do
          let(:parole_eligibility_date) { Time.zone.today - 1.year }
  
          it 'returns parole_eligibility_date' do
            expect(subject.next_parole_date).to eq parole_eligibility_date
          end
        end
      end
  
      context 'when target_hearing_date is available' do
        let(:target_hearing_date) { Time.zone.today + 5.years }
  
        it 'returns the target_hearing_date regardless of whether it is the earliest date' do
          expect(subject.next_parole_date).to eq target_hearing_date
        end
      end
    end
  
    describe '#next_parole_date_type' do
      context 'when next_parole_date is tariff_date' do
        it 'returns "TED"' do
          allow(subject).to receive(:next_parole_date).and_return(tariff_date)
  
          expect(subject.next_parole_date_type).to eq 'TED'
        end
      end
  
      context 'when next_parole_date is parole_eligibility_date' do
        it 'returns "TED"' do
          allow(subject).to receive(:next_parole_date).and_return(parole_eligibility_date)
  
          expect(subject.next_parole_date_type).to eq 'PED'
        end
      end
  
      context 'when next_parole_date is target_hearing_date' do
        it 'returns "TED"' do
          allow(subject).to receive(:next_parole_date).and_return(target_hearing_date)
  
          expect(subject.next_parole_date_type).to eq 'Target hearing date'
        end
      end
    end

    context 'when the offender has an upcoming parole hearing' do
      describe '#next_thd' do
        it 'returns the target hearing date of the incomplete parole record' do
          expect(subject.next_thd).to eq(parole_record.target_hearing_date)
        end
      end

      describe '#target_hearing_date' do
        it 'returns the target hearing date of the incomplete parole record' do
          expect(subject.target_hearing_date).to eq(parole_record.target_hearing_date)
        end
      end

      describe '#hearing_outcome_received' do
        it 'returns nil' do
          expect(subject.hearing_outcome_received).to eq(nil)
        end
      end

      describe '#last_hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(subject.last_hearing_outcome_received).to eq(completed_parole_record.hearing_outcome_received)
        end
      end
    end

    context 'when the offender does not have an upcoming parole hearing' do
      before do
        allow(offender_model).to receive(:most_recent_parole_record).and_return(completed_parole_record)
        allow(offender_model).to receive(:parole_record_awaiting_hearing).and_return(nil)
      end

      describe '#next_thd' do
        it 'returns nil' do
          expect(subject.next_thd).to eq(nil)
        end
      end

      describe '#target_hearing_date' do
        it 'returns the target hearing date of the most recent completed parole record' do
          expect(subject.target_hearing_date).to eq(completed_parole_record.target_hearing_date)
        end
      end

      describe '#hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(subject.hearing_outcome_received).to eq(completed_parole_record.hearing_outcome_received)
        end
      end

      describe '#last_hearing_outcome_received' do
        it 'returns the hearing outcome received date of the most recent completed parole record' do
          expect(subject.last_hearing_outcome_received).to eq(completed_parole_record.hearing_outcome_received)
        end
      end
    end
  end
end
