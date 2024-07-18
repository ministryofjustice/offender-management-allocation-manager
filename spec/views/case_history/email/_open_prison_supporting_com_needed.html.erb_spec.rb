describe "case_history/email/_open_prison_supporting_com_needed" do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:email_history) do
    offender = create(:offender)
    create(
      :email_history,
      event: EmailHistory::OPEN_PRISON_SUPPORTING_COM_NEEDED,
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
    expect(page).to have_css(".moj-timeline__description", text: "Request for supporting COM to be allocated after move to open prison sent to test@email.com")
  end
end
