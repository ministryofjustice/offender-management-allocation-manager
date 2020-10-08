require 'rails_helper'

describe HmppsApi::Offender do
  describe '#handover_start_date' do
    context 'when in custody' do
      let(:offender) {
        build(:offender).tap { |o|
          o.sentence = HmppsApi::SentenceDetail.new(automatic_release_date: Time.zone.today + 1.year,
                                                 sentence_start_date: Time.zone.today)
          o.load_case_information(build(:case_information, case_allocation: 'NPS', mappa_level: 0))
        }
      }

      it 'has a value' do
        expect(offender.handover_start_date).not_to eq(nil)
      end
    end

    context 'when COM responsible already' do
      let(:offender) {
        build(:offender).tap { |o|
          o.sentence = HmppsApi::SentenceDetail.new
          o.load_case_information(build(:case_information))
        }
      }

      it 'doesnt has a value' do
        expect(offender.handover_start_date).to eq(nil)
      end
    end
  end

  describe '#pom_responsibility' do
    context 'when a Responsibility record does not exist' do
      let(:offender) { build(:offender, :indeterminate, latestLocationId: 'LEI') }

      it 'calculates the responsibility based on the offenders sentence' do
        responsibility = offender.pom_responsibility
        expect(responsibility.case_owner).to eq('Custody')
        expect(responsibility.custody?).to eq(true)
        expect(responsibility.description).to eq('Responsible')
      end
    end

    context 'when a Responsibility record exists' do
      let(:offender) { build(:offender, :indeterminate, latestLocationId: 'LEI') }

      it "returns Supporting when Responsibility.value is 'Probation'" do
        case_info = create(:case_information, nomis_offender_id: offender.offender_no, case_allocation: 'NPS', mappa_level: 0)
        create(:responsibility, nomis_offender_id: offender.offender_no, value: 'Probation')

        # Offender is not a typical model where we can 'reload' when the record has changed.
        # Using load_case_information will load the case information record and responsibility (if it exists)
        # This method is not explicitly called in pom_responsibility method as the Offender model gets created
        # everytime it is request, so the case information will be automatically loaded.
        offender.load_case_information(case_info)

        responsibility = offender.pom_responsibility
        expect(responsibility.case_owner).to eq('Community')
        expect(responsibility.custody?).to eq(false)
        expect(responsibility.description).to eq('Supporting')
      end

      it "returns Responsible when Responsibility.value is 'Prison'" do
        case_info = create(:case_information, nomis_offender_id: offender.offender_no, case_allocation: 'NPS', mappa_level: 0)
        create(:responsibility, nomis_offender_id: offender.offender_no, value: 'Prison')

        offender.load_case_information(case_info)

        responsibility = offender.pom_responsibility
        expect(responsibility.case_owner).to eq('Custody')
        expect(responsibility.custody?).to eq(true)
        expect(responsibility.description).to eq('Responsible')
      end
    end
  end
end
