require 'rails_helper'

RSpec.describe OverrideHelper do
  let(:allocation_one) {
    build(:allocation,
          primary_pom_nomis_id: 485_833,
          nomis_offender_id: 'G2911GD',
          recommended_pom_type: 'prison',
          suitability_detail: "Prisoner too high risk",
          override_detail: "Concerns around behaviour"
    )
  }

  let(:allocation_two) {
    build(:allocation,
          primary_pom_nomis_id: 485_833,
          nomis_offender_id: 'G2911GD',
          recommended_pom_type: nil
    )
  }

  describe '#complex_reason_label' do
    context 'when a prison POM' do
      # Immigration cases are always recommended to Prison POMs
      let(:subject) { OffenderPresenter.new(OpenStruct.new(immigration_case?: true, nps_case?: false), nil) }

      it "can get for a prison owned offender" do
        expect(subject.complex_reason_label).to eq('Prisoner assessed as not suitable for a prison officer POM')
      end
    end

    context 'when a probation POM' do
      let(:crd)         { Time.zone.today + 15.months }
      let(:start_date)  { Time.zone.today }
      let(:subject)     {
        OffenderPresenter.new(OpenStruct.new(
                                immigration_case?: false,
                                tier: 'A',
                                nps_case?: true,
                                sentence_start_date: start_date,
                                conditional_release_date: crd),
                              nil)
      }

      it "can get for a probation owned offender" do
        expect(subject.complex_reason_label).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
      end
    end
  end

  describe '#display_override_pom' do
    it 'displays which POM type was overriden, if present' do
      expect(display_override_pom(allocation_one)).to eq('Probation POM allocated instead of recommended Prison POM')
    end

    it 'displays generic message if POM type not present' do
      expect(display_override_pom(allocation_two)).to eq('Prisoner not allocated to recommended POM')
    end
  end

  describe '#display_override_details' do
    it 'displays which recommended POM type was not available, when present' do
      expect(display_override_details("no_staff", allocation_one)).to include('No available prison POMs')
    end

    it 'displays a generic message if reason is POM type not available, and the POM type is not present' do
      expect(display_override_details("no_staff", allocation_two)).to include('No available recommended POMs')
    end

    it 'displays the reason the prisoner wasn\'t suitable for the recommended POM type' do
      expect(display_override_details("suitability", allocation_one)).to include('Prisoner too high risk')
    end

    it 'returns that the POM has worked with the prisoner before ' do
      expect(display_override_details("continuity", allocation_one)).to include('This POM has worked with the prisoner before')
    end

    it "returns the details for choosing 'other reason'" do
      expect(display_override_details("other", allocation_one)).to include('Other reason')
      expect(display_override_details("other", allocation_one)).to include('Concerns around behaviour')
    end
  end
end
