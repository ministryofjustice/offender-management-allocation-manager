require 'rails_helper'

RSpec.describe MpcOffender, type: :model do
  subject(:offender) do
    described_class.new(prison: prison, offender: offender_model, prison_record: api_offender)
  end

  let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
  let(:offender_model) do
    instance_double(Offender,
                    id: nomis_offender_id,
                    nomis_offender_id: nomis_offender_id,
                    case_information: instance_double(CaseInformation),
                    calculated_handover_date: instance_double(CalculatedHandoverDate, handover_date: nil, reason: nil))
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

  describe '#prison_timeline' do
    context 'when API returns a value' do
      before do
        allow(HmppsApi::PrisonTimelineApi).to receive(:get_prison_timeline).and_return(timeline)
      end

      let(:timeline) { {} }

      it 'returns nil' do
        expect(subject.prison_timeline).to eq(timeline)
      end
    end

    context 'when API returns 404' do
      before do
        allow(HmppsApi::PrisonTimelineApi).to receive(:get_prison_timeline).and_raise(Faraday::ResourceNotFound.new(nil))
      end

      it 'returns nil' do
        expect(subject.prison_timeline).to eq(nil)
      end
    end

    context 'when API returns 500' do
      before do
        allow(HmppsApi::PrisonTimelineApi).to receive(:get_prison_timeline).and_raise(Faraday::ServerError.new(nil))
      end

      it 'returns nil' do
        expect(subject.prison_timeline).to eq(nil)
      end
    end
  end

  describe '#rosh_summary' do
    before do
      allow_any_instance_of(described_class).to receive(:crn).and_return('ABC123')
    end

    context 'when probation record missing' do
      before do
        subject.instance_variable_set(:@case_information, nil)
      end

      it 'returns status unable' do
        expect(subject.rosh_summary).to eq({ status: :unable })
      end
    end

    context 'when CRN is blank' do
      before do
        allow_any_instance_of(described_class).to receive(:crn).and_return(nil)
      end

      it 'returns status unable' do
        expect(subject.rosh_summary).to eq({ status: :unable })
      end
    end

    context 'when API resource not found' do
      before do
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_raise(Faraday::ResourceNotFound.new(nil))
      end

      it 'returns status missing' do
        expect(subject.rosh_summary).to eq({ status: :missing })
      end
    end

    context 'when API forbidden' do
      before do
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_raise(Faraday::ForbiddenError.new(nil))
      end

      it 'returns status unable' do
        expect(subject.rosh_summary).to eq({ status: :unable })
      end
    end

    context 'when API error' do
      before do
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_raise(Faraday::ServerError.new(nil))
      end

      it 'returns status unable' do
        expect(subject.rosh_summary).to eq({ status: :unable })
      end
    end

    context 'when successful API call' do
      before do
        allow_any_instance_of(described_class).to receive(:crn).and_return('ABC123')
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_return(fake_response)
      end

      let(:fake_response) do
        {
          'summary' => {
            'riskInCommunity' => {
              'HIGH' => ['Children'],
              'MEDIUM' => ['Public', 'Staff'],
              'LOW' => ['Known Adult']
            },
            'riskInCustody' => {
              'HIGH' => ['Know adult'],
              'VERY_HIGH' => ['Staff', 'Prisoners'],
              'LOW' => ['Children', 'Public']
            },
            'overallRiskLevel' => 'HIGH'
          },
          'assessedOn' => '2022-07-05T15:29:01',
        }
      end

      it 'returns correct level for each risk' do
        expect(subject.rosh_summary).to eq(
          {
            status: 'found',
            overall: 'HIGH',
            last_updated: Date.new(2022, 7, 5),
            custody: {
              children: 'low',
              public: 'low',
              known_adult: 'high',
              staff: 'very high',
              prisoners: 'very high'
            },
            community: {
              children: 'high',
              public: 'medium',
              known_adult: 'low',
              staff: 'medium',
              prisoners: nil
            }
          }
        )
      end
    end
  end

  describe '#active_alert_labels' do
    let(:api_result) do
      [
        { "alertCodeDescription" => "Apples", "active" => true, "dateCreated" => "2022-01-01" },
        { "alertCodeDescription" => "Pears", "active" => true, "dateCreated" => "2022-01-02" },
        { "alertCodeDescription" => "Bananas", "active" => false, "dateCreated" => "2021-06-04" },
        { "alertCodeDescription" => "Artichokes", "active" => false, "dateCreated" => "2021-01-01" },
        { "alertCodeDescription" => "Carrots", "active" => false, "dateCreated" => "2021-01-01" }
      ]
    end

    before do
      allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender_alerts).and_return(api_result)
    end

    it 'returns correct filtered and sorted list' do
      expect(subject.active_alert_labels).to eq(["Pears", "Apples"])
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
        earliest_release_for_handover
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
        manual_entry?
        handover_type
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

  describe '#has_com?' do
    it 'is true if COM email is given and COM name is blank' do
      allow(offender_model.case_information).to receive_messages(com_email: 'a@b', com_name: nil)
      expect(subject.has_com?).to eq true
    end

    it 'is true if COM email is blank and COM name is given' do
      allow(offender_model.case_information).to receive_messages(com_email: nil, com_name: 'A B')
      expect(subject.has_com?).to eq true
    end

    it 'is false if COM email and COM name are both blank' do
      allow(offender_model.case_information).to receive_messages(com_email: nil, com_name: nil)
      expect(subject.has_com?).to eq false
    end
  end

  describe '#determinate_parole?' do
    it 'is true if parole eligibility date is present' do
      allow(api_offender).to receive(:parole_eligibility_date).and_return(Faker::Date.rand)
      expect(subject.determinate_parole?).to eq true
    end

    it 'is false if parole eligibility date is absent' do
      allow(api_offender).to receive(:parole_eligibility_date).and_return(nil)
      expect(subject.determinate_parole?).to eq false
    end
  end

  describe '#to_allocated_offender' do
    describe 'when allocation history exists' do
      it 'build an AllocatedOffender' do
        alloc_history = FactoryBot.create :allocation_history, :primary, nomis_offender_id: offender.offender_no,
                                                                         prison: offender.prison.code
        alloc_offender = instance_double AllocatedOffender
        allow(AllocatedOffender).to receive(:new).with(alloc_history.primary_pom_nomis_id, alloc_history, offender)
                                                 .and_return(alloc_offender)
        expect(offender.to_allocated_offender).to eq alloc_offender
      end
    end

    describe 'when allocation history is not there' do
      it 'returns nil' do
        allow(AllocatedOffender).to receive(:new)

        aggregate_failures do
          expect(offender.to_allocated_offender).to eq nil
          expect(AllocatedOffender).not_to have_received(:new)
        end
      end
    end
  end

  describe '#earliest_release_for_handover' do
    it 'uses official calculations correctly' do
      expected = double :expected

      allow(offender).to receive_messages(
        indeterminate_sentence?: double(:indeterminate_sentence?),
        tariff_date: double(:tariff_date),
        target_hearing_date: double(:target_hearing_date),
        parole_eligibility_date: double(:parole_eligibility_date),
        automatic_release_date: double(:automatic_release_date),
        conditional_release_date: double(:conditional_release_date),
      )

      allow(Handover::HandoverCalculation).to receive_messages(calculate_earliest_release: expected)

      aggregate_failures do
        expect(offender.earliest_release_for_handover).to eq expected

        expect(Handover::HandoverCalculation).to have_received(:calculate_earliest_release)
                                                   .with(is_indeterminate: offender.indeterminate_sentence?,
                                                         tariff_date: offender.tariff_date,
                                                         target_hearing_date: offender.target_hearing_date,
                                                         parole_eligibility_date: offender.parole_eligibility_date,
                                                         automatic_release_date: offender.automatic_release_date,
                                                         conditional_release_date: offender.conditional_release_date)
      end
    end
  end
end
