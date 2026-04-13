# frozen_string_literal: true

RSpec.shared_context 'with missing information feature defaults' do
  let(:review_case_offender_no) { offender.fetch(:prisonerNumber) }

  before do
    stub_signin_spo(user, [prison.code])
    stub_poms(prison.code, [user])
    stub_offenders_for_prison(prison.code, offenders)
    stub_keyworker(review_case_offender_no)
    stub_community_offender(review_case_offender_no, build(:community_data))
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return(RoshSummary.missing)
  end

  def start_missing_information_journey(prison_code:, prisoner_id:)
    visit missing_information_prison_prisoners_path(prison_code)
    within "#edit_#{prisoner_id}" do
      click_link 'Add missing details'
    end
  end

  def expect_case_information_page(prison_code:, prisoner_id:, expected_path: new_prison_prisoner_case_information_path(prison_code, prisoner_id))
    expect(page).to have_current_path(expected_path, ignore_query: true)
    expect(page).to have_content('Add missing details for')
    expect(page).to have_content('What is this person’s tier?')
  end

  def fill_in_case_information(resourcing:, tier:)
    find("label[for=case-information-enhanced-resourcing-#{resourcing}-field]").click
    find("label[for=case-information-tier-#{tier.downcase}-field]").click
  end
end
