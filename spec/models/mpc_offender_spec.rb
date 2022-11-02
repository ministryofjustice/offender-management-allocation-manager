require 'rails_helper'

RSpec.describe MpcOffender, type: :model do
  subject do
    build(:mpc_offender, prison: prison, prison_record: api_offender, offender: build(:case_information).offender)
  end

  let(:prison) { build(:prison) }
  let(:api_offender) { double(:nomis_offender, offender_no: 'AB000C') }

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
end
