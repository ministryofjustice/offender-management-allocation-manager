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

  describe 'fields that come from CaseInformation' do
    context 'when no CaseInformation has been loaded' do
      subject { offender.public_send(field) }

      let(:offender) { build(:offender) }

      shared_examples 'expect fields to be' do |value, fields|
        fields.each do |field|
          describe "##{field}" do
            let(:field) { field }

            it { is_expected.to be(value) }
          end
        end
      end

      include_examples 'expect fields to be', nil, [
        :tier, :case_allocation, :mappa_level, :parole_review_date,
        :welsh_offender, :ldu, :team, :allocated_com_name
      ]

      include_examples 'expect fields to be', false, [
        :has_case_information?, :early_allocation?
      ]
    end

    context 'when a CaseInformation record has been loaded' do
      subject { offender.public_send(field) }

      let(:case_info) { create(:case_information) }
      let(:offender) { build(:offender).tap { |o| o.load_case_information(case_info) } }

      describe '#has_case_information?' do
        let(:field) { :has_case_information? }

        it { is_expected.to be(true) }
      end

      delegated_fields = [:tier, :case_allocation, :mappa_level, :parole_review_date]
      delegated_fields.each do |delegated_field|
        describe "##{delegated_field}" do
          let(:field) { delegated_field }

          it { is_expected.to be(case_info.public_send(delegated_field)) }
        end
      end

      describe '#welsh_offender' do
        let(:field) { :welsh_offender }

        context 'when the welsh_offender field is "Yes"' do
          let(:case_info) { create(:case_information, welsh_offender: 'Yes') }

          it { is_expected.to be(true) }
        end

        context 'when the welsh_offender field is "No"' do
          let(:case_info) { create(:case_information, welsh_offender: 'No') }

          it { is_expected.to be(false) }
        end
      end

      describe '#early_allocation?' do
        let(:field) { :early_allocation? }

        context 'when eligible for early allocation' do
          let!(:early_allocation) { create(:early_allocation, case_information: case_info) }

          it { is_expected.to be(true) }
        end

        context 'when ineligible for early allocation' do
          let!(:early_allocation) { create(:early_allocation, :ineligible, :skip_validate, case_information: case_info) }

          it { is_expected.to be(false) }
        end

        context 'when discretionary but the community have accepted' do
          let!(:early_allocation) { create(:early_allocation, :discretionary, community_decision: true, case_information: case_info) }

          it { is_expected.to be(true) }
        end
      end

      describe '#ldu' do
        let(:field) { :ldu }

        it { is_expected.to be(case_info.team.local_divisional_unit) }
      end

      describe '#team' do
        let(:field) { :team }

        it { is_expected.to be(case_info.team.name) }
      end

      describe '#allocated_com_name' do
        let(:case_info) { create(:case_information, :with_com) }
        let(:field) { :allocated_com_name }

        it { is_expected.to be(case_info.com_name) }
      end
    end
  end
end
