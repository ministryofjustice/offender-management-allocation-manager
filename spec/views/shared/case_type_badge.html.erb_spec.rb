require 'rails_helper'

RSpec.describe "allocations/new", type: :view do
  let(:prison) { build(:prison) }
  let(:page) { Nokogiri::HTML(rendered) }
  let(:case_type_badge) { page.css('#prisoner-case-type') }
  let(:recall_badge) { page.css('#recall-badge') }
  let(:parole_badge) { page.css('#parole-badge') }
  let(:parole_review_date) { page.css('#parole-review-date') }

  before do
    assign(:prison, prison)
    assign(:recommended_poms, [])
    assign(:not_recommended_poms, [])
    assign(:unavailable_pom_count, 0)
    assign(:prisoner, OffenderPresenter.new(offender))
    render
  end

  context "when indeterminate" do
    let(:offender) { build(:offender, :indeterminate) }

    it "displays an indeterminate case type badge" do
      assert_you_have_an_indeterminate_badge
    end
  end

  context "when determinate" do
    let(:offender) { build(:offender, :determinate) }

    it "displays an determinate case type badge" do
      assert_you_have_a_determinate_badge
    end
  end

  context "when recall" do
    let(:offender) { build(:offender, :indeterminate_recall) }

    it "displays a recall case type badge and a indeterminate badge" do
      expect(case_type_badge.first.attributes['class'].value).to include 'moj-badge--purple'
      expect(case_type_badge.text).to include 'Indeterminate'
      assert_you_have_a_recall_badge
    end
  end

  context "when parole eligibility(PED)" do
    let(:offender) { build(:offender, :indeterminate, sentence: build(:sentence_detail, paroleEligibilityDate: Time.zone.today.to_s)) }

    it "displays an parole eligibility case type badge" do
      assert_you_have_a_parole_eligibility_badge
      assert_you_have_an_indeterminate_badge
    end
  end

  context "when parole eligibility(TED)" do
    let(:offender) { build(:offender, :determinate, sentence: build(:sentence_detail, tariffDate: Time.zone.today.to_s)) }

    it "displays an parole eligibility case type badge and determinate badge" do
      assert_you_have_a_parole_eligibility_badge
      assert_you_have_a_determinate_badge
    end
  end

  context "when there is a parole review date" do
    let(:offender_no) { 'G7514GW' }
    let(:case_information) { build(:case_information,  nomis_offender_id: offender_no, parole_review_date: Date.new(2019, 0o1, 3).to_s) }
    let(:offender) {
      offender = build(:offender, :indeterminate, offenderNo: offender_no)
      offender.load_case_information(case_information)
      offender
    }

    it "displays an parole eligibility case type badge" do
      assert_you_have_an_indeterminate_badge
      expect(parole_review_date.text).to include '03/01/2019'
      assert_you_have_a_parole_eligibility_badge
    end
  end

  context 'when parole eligibility (both TED and PRD) and parole review date are nil' do
    let(:offender_no) { 'G7514GW' }
    let(:case_information) { build(:case_information,  nomis_offender_id: offender_no) }
    let(:offender) {
      offender = build(:offender, :indeterminate, offenderNo: offender_no)
      offender.load_case_information(case_information)
      offender
    }

    it 'does not display the badge' do
      expect(offender.tariff_date).to eq nil
      expect(offender.parole_review_date).to eq nil
      expect(offender.parole_eligibility_date).to eq nil
      expect(parole_review_date.text).not_to include '01/03/2019'
      expect(parole_badge.text).not_to include 'Parole eligible'
    end
  end

  context "when indeterminate, a recall case and parole eligibility(PED)" do
    let(:offender) { build(:offender, :indeterminate_recall, sentence: build(:sentence_detail, paroleEligibilityDate: Time.zone.today.to_s)) }

    it "displays an indeterminate, parole eligibility and recall case type badges" do
      assert_you_have_an_indeterminate_badge
      assert_you_have_a_parole_eligibility_badge
      assert_you_have_a_recall_badge
    end
  end

  context "when determinate, a recall case and parole eligibility(PED)" do
    let(:offender) { build(:offender, :determinate_recall, sentence: build(:sentence_detail, paroleEligibilityDate: Time.zone.today.to_s)) }

    it "displays an determinate, parole eligibility and recall case type badges" do
      assert_you_have_a_determinate_badge
      assert_you_have_a_parole_eligibility_badge
      assert_you_have_a_recall_badge
    end
  end

  def assert_you_have_a_parole_eligibility_badge
    expect(parole_badge.first.attributes['class'].value).to include 'moj-badge--grey'
    expect(parole_badge.text).to include 'Parole eligible'
  end

  def assert_you_have_a_determinate_badge
    expect(case_type_badge.first.attributes['class'].value).to include 'moj-badge--blue'
    expect(case_type_badge.text).to include 'Determinate'
  end

  def assert_you_have_a_recall_badge
    expect(recall_badge.first.attributes['class'].value).to include 'moj-badge--grey'
    expect(recall_badge.text).to include 'Recall'
  end

  def assert_you_have_an_indeterminate_badge
    expect(case_type_badge.first.attributes['class'].value).to include 'moj-badge--purple'
    expect(case_type_badge.text).to include 'Indeterminate'
  end
end
