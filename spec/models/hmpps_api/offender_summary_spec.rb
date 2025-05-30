# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::Offender do
  let(:prison) { build(:prison) }

  describe '#responsibility_override?' do
    context 'when no responsibility found for offender' do
      let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate)) }

      it 'returns false' do
        subject = build(:mpc_offender, prison: prison, offender: build(:case_information).offender, prison_record: api_offender)
        expect(subject.responsibility_override?).to eq(false)
      end
    end

    it 'returns true when there is a responsibility found for an offender' do
      # create case information and responsibility record
      case_info = create(:case_information, offender: build(:offender, nomis_offender_id: 'A1234XX'))
      create(:responsibility, nomis_offender_id: 'A1234XX')

      # build an offender
      api_offender = build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate), prisonerNumber: 'A1234XX')
      offender = build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender)

      expect(offender.responsibility_override?).to eq(true)
    end
  end

  describe '#within_early_allocation_window?' do
    context 'with no dates' do
      let(:api_offender) do
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail,
                                                            conditionalReleaseDate: nil,
                                                            automaticReleaseDate: nil))
      end
      let(:case_info) { build(:case_information) }
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it 'is not within window' do
        expect(offender.within_early_allocation_window?).to eq(false)
      end
    end

    context 'when ARD > 18 months' do
      let(:api_offender) do
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :blank,
                                                            automaticReleaseDate: Time.zone.today + 19.months
        ))
      end
      let(:case_info) { build(:case_information) }
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it 'is not within window' do
        expect(offender.within_early_allocation_window?).to eq(false)
      end
    end

    context 'when ARD < 18 months' do
      let(:api_offender) do
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :blank,
                                                            automaticReleaseDate: Time.zone.today + 17.months))
      end
      let(:case_info) { build(:case_information) }
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end

    context 'when TED < 18 months' do
      let(:case_info) do
        build(:case_information, offender: build(:offender,
                                                 parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 24.months)]))
      end
      let(:api_offender) do
        build(:hmpps_api_offender,
              sentence: attributes_for(:sentence_detail,
                                       conditionalReleaseDate: Time.zone.today + 24.months,
                                       tariffDate: Time.zone.today + 17.months,
                                       automaticReleaseDate: Time.zone.today + 24.months))
      end
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end

    context 'when PED < 18 months' do
      let(:case_info) do
        build(:case_information, offender: build(:offender,
                                                 parole_reviews: [build(:parole_review, target_hearing_date: Time.zone.today + 24.months)]))
      end
      let(:api_offender) do
        build(:hmpps_api_offender,
              sentence: attributes_for(:sentence_detail,
                                       conditionalReleaseDate: Time.zone.today + 24.months,
                                       tariffDate: Time.zone.today + 24.months,
                                       paroleEligibilityDate: Time.zone.today + 17.months,
                                       automaticReleaseDate: Time.zone.today + 24.months))
      end
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it 'is within window' do
        expect(offender.within_early_allocation_window?).to eq(true)
      end
    end
  end

  describe '#pom_responsibility' do
    subject { OffenderManagerResponsibility.new offender.pom_responsible?, offender.pom_supporting? }

    let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate), prisonId: 'LEI') }

    before do
      stub_auth_token
    end

    context 'when the responsibility has not been overridden' do
      let(:case_info) { build(:case_information) }
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it "calculates the responsibility based on the offender's sentence" do
        # POM is responsible because TED is 1 year away
        expect(subject).to be_responsible
      end
    end

    context 'when the responsibility has been overridden' do
      let(:offender) do
        case_info = create(:case_information, offender: build(:offender, nomis_offender_id: api_offender.offender_no), enhanced_resourcing: true, mappa_level: 0)

        # Responsibility overrides exist as 'Responsibility' records
        create(:responsibility, nomis_offender_id: api_offender.offender_no, value: override_to)

        build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender)
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
    subject { OffenderManagerResponsibility.new offender.com_responsible?, offender.com_supporting? }

    let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate), prisonId: 'LEI') }

    before do
      stub_auth_token
    end

    context 'when the responsibility has not been overridden' do
      let(:case_info) { build(:case_information) }
      let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

      it "calculates the responsibility based on the offender's sentence" do
        # Offender's TED is 1 year away, so a COM isn't needed yet
        expect(subject).not_to be_involved
      end
    end

    context 'when the responsibility has been overridden' do
      let(:offender) do
        case_info = create(:case_information, offender: build(:offender, nomis_offender_id: api_offender.offender_no), enhanced_resourcing: true, mappa_level: 0)

        # Responsibility overrides exist as 'Responsibility' records
        create(:responsibility, nomis_offender_id: api_offender.offender_no, value: override_to)
        build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender)
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
    subject { offender.public_send(field) }

    let(:case_info) { create(:case_information) }
    let(:api_offender) { build(:hmpps_api_offender) }
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    delegated_fields = [:tier, :mappa_level]
    delegated_fields.each do |delegated_field|
      describe "##{delegated_field}" do
        let(:field) { delegated_field }

        it { is_expected.to be(case_info.public_send(delegated_field)) }
      end
    end

    describe '#welsh_offender' do
      let(:field) { :welsh_offender }

      context 'with a welsh_offender' do
        let(:case_info) { create(:case_information, :welsh) }

        it { is_expected.to be(true) }
      end

      context 'with and english offender' do
        let(:case_info) { create(:case_information, :english) }

        it { is_expected.to be(false) }
      end
    end

    describe '#early_allocation?' do
      let(:field) { :early_allocation? }

      context 'when eligible for early allocation' do
        let!(:early_allocation) { create(:early_allocation, offender: case_info.offender) }

        it { is_expected.to be(true) }
      end

      context 'when ineligible for early allocation' do
        let!(:early_allocation) { create(:early_allocation, :ineligible, offender: case_info.offender) }

        it { is_expected.to be(false) }
      end

      context 'when discretionary but the community have accepted' do
        let!(:early_allocation) { create(:early_allocation, :discretionary, community_decision: true, offender: case_info.offender) }

        it { is_expected.to be(true) }
      end
    end

    describe '#ldu_name' do
      let(:field) { :ldu_name }

      context 'with a local delivery unit' do
        let(:ldu) { create(:local_delivery_unit) }
        let(:case_info) { create(:case_information, local_delivery_unit: ldu) }

        it { is_expected.to be(ldu.name) }
      end

      context 'without a local delivery unit' do
        let(:case_info) { create(:case_information, local_delivery_unit: nil) }

        it { is_expected.to be_nil }
      end
    end

    describe '#ldu_email_address' do
      let(:field) { :ldu_email_address }

      context 'with a local delivery unit' do
        let(:ldu) { create(:local_delivery_unit) }
        let(:case_info) { create(:case_information, local_delivery_unit: ldu) }

        it { is_expected.to be(ldu.email_address) }
      end

      context 'without a local delivery unit' do
        let(:case_info) { create(:case_information, local_delivery_unit: nil) }

        it { is_expected.to be_nil }
      end
    end

    describe '#team_name' do
      let(:field) { :team_name }

      it { is_expected.to be(case_info.team_name) }
    end

    describe '#allocated_com_name' do
      let(:case_info) { create(:case_information, :with_com) }
      let(:field) { :allocated_com_name }

      it { is_expected.to be(case_info.com_name) }
    end
  end

  describe '#needs_a_com?' do
    subject { offender.needs_a_com? }

    let(:api_offender) do
      build(:hmpps_api_offender, sentence: sentence)
    end
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    let(:case_info) { build(:case_information) }

    context 'when the Community is not involved yet' do
      let(:sentence) { attributes_for(:sentence_detail, paroleEligibilityDate: Time.zone.today + 1.year + 8.days) }

      it 'returns false' do
        expect(subject).to be(false)
      end
    end

    context 'when the Community is involved' do
      let(:sentence) { attributes_for(:sentence_detail, conditionalReleaseDate: Time.zone.today + 7.months) }

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

  describe 'offender category' do
    subject { build(:hmpps_api_offender, category: category) }

    context 'with a male offender (Cat B)' do
      let(:category) { build(:offender_category, :cat_b) }

      it 'knows the category code' do
        expect(subject.category_code).to eq('B')
      end

      it 'knows the category label' do
        expect(subject.category_label).to eq('Cat B')
      end

      it 'knows when the category became active for this offender' do
        expect(subject.category_active_since).to be_a(Date)
      end
    end

    context 'with a female offender (Female Open)' do
      let(:category) { build(:offender_category, :female_open) }

      it 'knows the category code' do
        expect(subject.category_code).to eq('T')
      end

      it 'knows the category label' do
        expect(subject.category_label).to eq('Female Open')
      end

      it 'knows when the category became active for this offender' do
        expect(subject.category_active_since).to be_a(Date)
      end
    end

    # This is a legitimate state for an offender to be in
    # They could be in the prison, but a categorisation assessment hasn't been completed yet
    context "when the offender doesn't have a category" do
      let(:category) { nil }

      it 'returns nil' do
        expect(subject.category_code).to be_nil
        expect(subject.category_label).to be_nil
        expect(subject.category_active_since).to be_nil
      end
    end
  end
end
