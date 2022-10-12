RSpec.describe MpcOffender, type: :model do
  subject do
    build(:mpc_offender, prison: prison, prison_record: api_offender, offender: build(:case_information).offender)
  end

  let(:prison) { build(:prison) }
  let(:api_offender) { double(:nomis_offender, offender_no: 'AB000C') }

  describe '#rosh_summary' do
    before do
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
