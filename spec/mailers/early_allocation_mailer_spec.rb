require 'rails_helper'

RSpec.describe EarlyAllocationMailer, type: :mailer do
  describe 'review_early_allocation' do
    let(:params) do
      {
        prisoner_name: "Brown, James",
        start_page_link: prison_prisoner_early_allocations_path(prison_id: "LEI", prisoner_id: "T1000AA"),
        equip_guidance_link: "http://www.equip_guidance_link.html",
        email: "ursula.richards@thelighthouse.gov.uk"
      }
    end

    let(:mail) { described_class.review_early_allocation(params) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).to eq('502e057c-a875-4653-9b33-63dcfd33e582')
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq([params[:email]])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation)
      .to eq(prisoner_name: params[:prisoner_name],
             start_page_link: "/prisons/LEI/prisoners/T1000AA/early_allocations",
             equip_guidance_link: params[:equip_guidance_link]
            )
    end
  end
end
