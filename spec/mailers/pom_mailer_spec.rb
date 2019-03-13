require 'rails_helper'

RSpec.describe PomMailer, type: :mailer do
  describe 'new_allocation_email' do
    let(:pom_name) { "Jones, Ross" }
    let(:pom_email)       { "something@example.com" }
    let(:offender_name) { "Franks, Jason" }
    let(:offender_no) { "AB1234S" }
    let(:message) { "This is just a test" }
    let(:url) { "http:://example.com" }
    let(:mail) { described_class.new_allocation_email(pom_name, pom_email, offender_name, offender_no, message, url) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).
          to eq '9679ea4c-1495-4fa6-a00b-630de715e315'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["something@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).
          to eq(
            email_subject: 'New OMIC allocation',
            pom_name: pom_name,
            offender_name: offender_name,
            nomis_offender_id: offender_no,
            message: "Additional information: " + message,
            url: url
                 )
    end

    context 'when no optional message has been added to the email' do
      let(:message) { "" }

      it 'personalises the email' do
        expect(mail.govuk_notify_personalisation).
            to eq(
              email_subject: 'New OMIC allocation',
              pom_name: pom_name,
              offender_name: offender_name,
              nomis_offender_id: offender_no,
              message: message,
              url: url
                   )
      end
    end
  end

  describe 'deallocation_email' do
    let(:previous_pom_name) { "Pobee-Norris, Kath" }
    let(:previous_pom_email) { "another@example.com" }
    let(:new_pom_name) { "Jones, Ross" }
    let(:offender_name) { "Marks, Simon" }
    let(:offender_no) { "GE4595D" }
    let(:url) { "http:://example.com" }
    let(:prison) { "HMP Leeds" }
    let(:mail) { described_class.deallocation_email(previous_pom_name, previous_pom_email, new_pom_name, offender_name, offender_no, prison, url) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).
          to eq 'cd628495-6e7a-448e-b4ad-4d49d4d8567d'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["another@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).
          to eq(
            email_subject: 'OMIC case reallocation',
            previous_pom_name: previous_pom_name,
            new_pom_name: new_pom_name,
            offender_name: offender_name,
            nomis_offender_id: offender_no,
            prison: prison,
            url: url
             )
    end
  end
end
