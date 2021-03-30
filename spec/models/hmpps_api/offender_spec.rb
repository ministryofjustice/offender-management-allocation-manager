# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::Offender do
  describe '#responsibility_override?' do
    it 'returns false when no responsibility found for offender' do
      # build an offender, by default this does not have any case information or responsibility record
      subject = build(:offender, :indeterminate)
      expect(subject.responsibility_override?).to eq(false)
    end

    it 'returns true when there is a responsibility found for an offender' do
      # create case information and responsibility record
      case_info = create(:case_information, nomis_offender_id: 'A1234XX')
      create(:responsibility, nomis_offender_id: 'A1234XX')

      # build an offender
      offender = build(:offender, :indeterminate, offenderNo: 'A1234XX')

      # load the case information and responsibility record into the offender object
      offender.load_case_information(case_info)

      expect(offender.responsibility_override?).to eq(true)
    end
  end

  describe '#within_early_allocation_window?' do
    context 'with no dates' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail,
                                         conditionalReleaseDate: nil,
                                         automaticReleaseDate: nil
        ))
      }

      it 'is not within window' do
        expect(offender.within_early_allocation_window?).to eq(false)
      end
    end

    context 'when ARD > 18 months' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail,
                                         conditionalReleaseDate: Time.zone.today + 24.months,
                                         automaticReleaseDate: Time.zone.today + 19.months
        ))
      }

      it 'is not within window' do
        expect(offender.within_early_allocation_window?).to eq(false)
      end
    end

    context 'when ARD < 18 months' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail,
                                         conditionalReleaseDate: Time.zone.today + 24.months,
                                         automaticReleaseDate: Time.zone.today + 17.months))
      }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end

    context 'when PRD < 18 months' do
      let(:offender) {
        build(:offender,
              sentence: build(:sentence_detail,
                              conditionalReleaseDate: Time.zone.today + 24.months,
                              automaticReleaseDate: Time.zone.today + 24.months)).tap { |o|
          o.load_case_information(build(:case_information, parole_review_date: Time.zone.today + 17.months))
        }
      }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end

    context 'when TED < 18 months' do
      let(:offender) {
        build(:offender,
              sentence: build(:sentence_detail,
                              conditionalReleaseDate: Time.zone.today + 24.months,
                              tariffDate: Time.zone.today + 17.months,
                              automaticReleaseDate: Time.zone.today + 24.months)).tap { |o|
          o.load_case_information(build(:case_information, parole_review_date: Time.zone.today + 24.months))
        }
      }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end

    context 'when PED < 18 months' do
      let(:offender) {
        build(:offender,
              sentence: build(:sentence_detail,
                              conditionalReleaseDate: Time.zone.today + 24.months,
                              tariffDate: Time.zone.today + 24.months,
                              paroleEligibilityDate: Time.zone.today + 17.months,
                              automaticReleaseDate: Time.zone.today + 24.months)).tap { |o|
          o.load_case_information(build(:case_information, parole_review_date: Time.zone.today + 24.months))
        }
      }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end
  end

  describe '#handover_start_date' do
    context 'when in custody' do
      let(:offender) {
        build(:offender).tap { |o|
          o.sentence = HmppsApi::SentenceDetail.from_json('automaticReleaseDate' => (Time.zone.today + 1.year).to_s,
                                                          'sentenceStartDate' => Time.zone.today.to_s)
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
          o.sentence = build(:sentence_detail, conditionalReleaseDate: Time.zone.today + 1.week)
          o.load_case_information(build(:case_information))
        }
      }

      it 'doesnt has a value' do
        expect(offender.handover_start_date).to eq(nil)
      end
    end
  end

  describe '#pom_responsibility' do
    subject { offender.pom_responsibility }

    let(:offender) { build(:offender, :indeterminate, latestLocationId: 'LEI') }

    context 'when the responsibility has not been overridden' do
      it "calculates the responsibility based on the offender's sentence" do
        # POM is responsible because TED is 1 year away
        expect(subject).to be_responsible
      end
    end

    context 'when the responsibility has been overridden' do
      before do
        case_info = create(:case_information, nomis_offender_id: offender.offender_no, case_allocation: 'NPS', mappa_level: 0)

        # Responsibility overrides exist as 'Responsibility' records
        create(:responsibility, nomis_offender_id: offender.offender_no, value: override_to)

        # Load the case info record on to the offender object
        offender.load_case_information(case_info)
      end

      context 'when overridden to the community' do
        let(:override_to) { 'Probation' }

        it "is supporting" do
          expect(subject).to be_supporting
        end
      end

      context 'when overridden to custody' do
        # Overrides to custody aren't actually possible in the UI, so this scenario should never occur naturally in the real world
        let(:override_to) { 'Prison' }

        it "is responsible" do
          expect(subject).to be_responsible
        end
      end
    end
  end

  describe '#com_responsibility' do
    subject { offender.com_responsibility }

    let(:offender) { build(:offender, :indeterminate, latestLocationId: 'LEI') }

    context 'when the responsibility has not been overridden' do
      it "calculates the responsibility based on the offender's sentence" do
        # Offender's TED is 1 year away, so a COM isn't needed yet
        expect(subject).not_to be_involved
      end
    end

    context 'when the responsibility has been overridden' do
      before do
        case_info = create(:case_information, nomis_offender_id: offender.offender_no, case_allocation: 'NPS', mappa_level: 0)

        # Responsibility overrides exist as 'Responsibility' records
        create(:responsibility, nomis_offender_id: offender.offender_no, value: override_to)

        # Load the case info record on to the offender object
        offender.load_case_information(case_info)
      end

      context 'when overridden to the community' do
        let(:override_to) { 'Probation' }

        it "is responsible" do
          expect(subject).to be_responsible
        end
      end

      context 'when overridden to custody' do
        # Overrides to custody aren't actually possible in the UI, so this scenario should never occur naturally in the real world
        # One of the things to decide if/when implementing this is: what will COM responsibility be? Supporting or not involved?
        let(:override_to) { 'Prison' }

        it "is supporting" do
          expect(subject).to be_supporting
        end
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
          :welsh_offender, :ldu_name, :team_name, :allocated_com_name, :ldu_email_address
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

        context 'with a welsh_offender' do
          let(:case_info) { create(:case_information, probation_service: 'Wales') }

          it { is_expected.to be(true) }
        end

        context 'with and english offender' do
          let(:case_info) { create(:case_information, probation_service: 'England') }

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
          let!(:early_allocation) { create(:early_allocation, :ineligible, case_information: case_info) }

          it { is_expected.to be(false) }
        end

        context 'when discretionary but the community have accepted' do
          let!(:early_allocation) { create(:early_allocation, :discretionary, community_decision: true, case_information: case_info) }

          it { is_expected.to be(true) }
        end
      end

      describe '#ldu_name' do
        let(:field) { :ldu_name }

        context 'when there is a new LDU mapping' do
          let(:ldu) { create(:local_delivery_unit) }
          let(:case_info) { create(:case_information, local_delivery_unit: ldu) }

          it { is_expected.to be(ldu.name) }
        end

        context 'without a new LDU mapping' do
          let(:case_info) { create(:case_information) }

          it { is_expected.to be(case_info.team.local_divisional_unit.name) }
        end
      end

      describe '#ldu_email_address' do
        let(:field) { :ldu_email_address }

        context 'when there is a new LDU mapping' do
          let(:ldu) { create(:local_delivery_unit) }
          let(:case_info) { create(:case_information, local_delivery_unit: ldu) }

          it { is_expected.to be(ldu.email_address) }
        end

        context 'without a new LDU mapping' do
          let(:case_info) { create(:case_information) }

          it { is_expected.to be(case_info.team.local_divisional_unit.email_address) }
        end
      end

      describe '#team_name' do
        let(:field) { :team_name }

        it { is_expected.to be(case_info.team.name) }
      end

      describe '#allocated_com_name' do
        let(:case_info) { create(:case_information, :with_com) }
        let(:field) { :allocated_com_name }

        it { is_expected.to be(case_info.com_name) }
      end
    end
  end

  describe '#needs_a_com?' do
    subject { offender.needs_a_com? }

    let(:offender) {
      build(:offender, sentence: sentence).tap { |o|
        o.load_case_information(case_info)
      }
    }

    let(:case_info) { build(:case_information) }

    context 'when the Community is not involved yet' do
      let(:sentence) { build(:sentence_detail, :handover_in_8_days) }

      it 'returns false' do
        expect(subject).to be(false)
      end
    end

    context 'when the Community is involved' do
      let(:sentence) { build(:sentence_detail, conditionalReleaseDate: Time.zone.today + 7.months) }

      context 'when a COM is already allocated' do
        let(:case_info) { build(:case_information, :with_com) }

        it 'returns false' do
          expect(subject).to be(false)
        end
      end

      context 'when a COM has not been allocated yet' do
        it 'returns true' do
          expect(subject).to be(true)
        end
      end
    end
  end
end
