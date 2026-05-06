require 'rails_helper'

RSpec.describe OverrideHelper do
  let(:allocation_one) do
    build(:allocation_history,
          primary_pom_nomis_id: 485_833,
          nomis_offender_id: 'G2911GD',
          recommended_pom_type: 'prison',
          suitability_detail: "Prisoner too high risk",
          override_detail: "Concerns around behaviour"
         )
  end

  let(:allocation_two) do
    build(:allocation_history,
          primary_pom_nomis_id: 485_833,
          nomis_offender_id: 'G2911GD',
          recommended_pom_type: nil
         )
  end

  let(:allocation_three) do
    build(:allocation_history,
          primary_pom_nomis_id: 485_833,
          nomis_offender_id: 'G2911GD',
          recommended_pom_type: 'probation',
          suitability_detail: 'Needs continuity'
         )
  end

  describe '#display_override_pom' do
    it 'displays which POM type was overridden, if present' do
      expect(display_override_pom(allocation_one)).to eq('Probation POM allocated instead of recommended prison POM')
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

    it 'displays that the prisoner was not suitable for a prison POM when prison was recommended' do
      expect(display_override_details("suitability", allocation_one)).to match(/Assessed as not suitable for a prison POM/)
      expect(display_override_details("suitability", allocation_one)).to include('Prisoner too high risk')
      expect(display_override_details("suitability", allocation_one)).to include('app-override-reason--detail')
    end

    it 'displays that the prisoner was suitable for a prison POM when probation was recommended' do
      expect(display_override_details("suitability", allocation_three)).to match(/Assessed as suitable for a prison POM\s+despite probation POM recommendation/)
      expect(display_override_details("suitability", allocation_three)).to include('Needs continuity')
    end

    it 'displays a generic suitability message for the allocated POM if the recommendation is not present' do
      allocation_two.suitability_detail = 'Needs continuity'

      expect(display_override_details("suitability", allocation_two)).to match(/Assessed as suitable for allocated POM despite recommendation/)
      expect(display_override_details("suitability", allocation_two)).to include('Needs continuity')
    end

    it 'returns that the POM has worked with the prisoner before' do
      expect(display_override_details("continuity", allocation_one)).to include('This POM has worked with the prisoner before')
    end

    it "returns the details for choosing 'other reason'" do
      expect(display_override_details("other", allocation_one)).to include('Other reason')
      expect(display_override_details("other", allocation_one)).to include('Concerns around behaviour')
      expect(display_override_details("other", allocation_one)).to include('app-override-reason--detail')
    end
  end
end
