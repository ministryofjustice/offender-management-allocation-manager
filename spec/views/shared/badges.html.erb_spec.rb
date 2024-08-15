require 'rails_helper'

RSpec.describe "shared/badges", type: :view do
  let(:prison) { create(:prison) }
  let(:page) { Nokogiri::HTML(rendered) }
  let(:case_type_badge) { page.css('#prisoner-case-type') }
  let(:recall_badge) { page.css('#recall-badge') }
  let(:parole_badge) { page.css('#parole-badge') }
  let(:case_info) { build(:case_information) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

  before do
    assign(:prison, prison)
    assign(:previous_poms, [])
    assign(:probation_poms, [])
    assign(:prison_poms, [])
    assign(:unavailable_pom_count, 0)
    assign(:prisoner, offender)
    render partial: 'shared/badges', locals: { offender: offender }
  end

  context "when indeterminate" do
    let(:api_offender) do
      build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate))
    end

    it "displays an indeterminate case type badge" do
      assert_you_have_an_indeterminate_badge
    end
  end

  context "when determinate" do
    let(:api_offender) do
      build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate))
    end

    it "displays an determinate case type badge" do
      assert_you_have_a_determinate_badge
    end
  end

  context "when recall" do
    let(:api_offender) do
      build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :recall))
    end

    it "displays a recall case type badge and a indeterminate badge" do
      assert_you_have_a_recall_badge
    end
  end

  context "when eligibile for parole" do
    let(:api_offender) do
      build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :approaching_parole))
    end

    it "displays an parole eligibility badge" do
      assert_you_have_a_parole_eligibility_badge
    end
  end

  context "when indeterminate, a recall case" do
    let(:api_offender) do
      build(:hmpps_api_offender,
            sentence: attributes_for(:sentence_detail, :indeterminate_recall))
    end

    it "displays an indeterminate, parole eligibility and recall case type badges" do
      assert_you_have_an_indeterminate_badge
      assert_you_have_a_recall_badge
    end
  end

  context "when determinate, a recall case" do
    let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate_recall)) }

    it "displays an determinate, parole eligibility and recall case type badges" do
      assert_you_have_a_determinate_badge
      assert_you_have_a_recall_badge
    end
  end

  def assert_you_have_a_parole_eligibility_badge
    expect(parole_badge.first.attributes['class'].value).to include 'govuk-tag--grey'
    expect(parole_badge.text).to include 'Parole eligible'
  end

  def assert_you_have_a_determinate_badge
    expect(case_type_badge.first.attributes['class'].value).to include 'govuk-tag--blue'
    expect(case_type_badge.text).to include 'Determinate'
  end

  def assert_you_have_a_recall_badge
    expect(recall_badge.first.attributes['class'].value).to include 'govuk-tag--grey'
    expect(recall_badge.text).to include 'Recall'
  end

  def assert_you_have_an_indeterminate_badge
    expect(case_type_badge.first.attributes['class'].value).to include 'govuk-tag--purple'
    expect(case_type_badge.text).to include 'Indeterminate'
  end
end
