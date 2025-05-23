describe "Email history partials" do
  emails_and_descriptions = {
    EmailHistory::RESPONSIBILITY_OVERRIDE => \
      "Request for responsible COM to be allocated sent to test@email.com",
    EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION => \
      "Request for supporting COM to be allocated after move to open prison sent to test@email.com",
    EmailHistory::URGENT_PIPELINE_TO_COMMUNITY => \
      "Reminder that COM allocation still needed after handover sent to test@email.com",
    EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION => \
      "Request for COM to be allocated as this person has less than 10 months to serve sent to test@email.com",
    EmailHistory::COMMUNITY_EARLY_ALLOCATION => \
      "Notification that early allocation assessment submitted for review sent to test@email.com",
    EmailHistory::AUTO_EARLY_ALLOCATION => \
      "Notification that early allocation assessment has been approved sent to test@email.com"
  }

  emails_and_descriptions.each do |event, expected_description|
    it "renders the correct description for the event type" do
      email_history = create(
        :email_history,
        event:,
        nomis_offender_id: create(:offender).nomis_offender_id,
        email: "test@email.com",
        name: "Test Name",
        prison: "LEI"
      )

      render partial: email_history
      expect(Nokogiri::HTML(rendered)).to have_css(".moj-timeline__description", text: expected_description)
    end
  end
end
