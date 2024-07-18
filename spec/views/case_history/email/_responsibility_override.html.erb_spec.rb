RSpec.describe "case_history/email/_responsibility_override", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:email_history) do
    offender = create(:offender)
    create(
      :email_history,
      event: EmailHistory::RESPONSIBILITY_OVERRIDE,
      nomis_offender_id: offender.nomis_offender_id,
      email:  "test@email.com",
      name:   "Test Name",
      prison: "LEI"
    )
  end

  before do
    render partial: email_history
  end

  it "renders the correct content" do
    expect(page).to have_css(".moj-timeline__description", text: "Request for responsible COM to be allocated sent to test@email.com")
  end
end
