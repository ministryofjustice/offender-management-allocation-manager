require 'rails_helper'

RSpec.describe PomMailer, type: :mailer do
  describe 'new_allocation_email' do
    let(:params) do
      {
        pom_name: "Pom, Moic",
        pom_email: "something@example.com",
        responsibility: "supporting",
        offender_name: "Franks, Jason",
        offender_no: "AB1234S",
        message: "This is just a test",
        url: "http:://example.com"
      }
    end

    let(:mail) { described_class.new_allocation_email(params) }

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
            pom_name: params[:pom_name],
            responsibility: params[:responsibility],
            offender_name: params[:offender_name],
            nomis_offender_id: params[:offender_no],
            message: "Additional information: " + params[:message],
            url: params[:url]
                 )
    end

    context 'when no optional message has been added to the email' do
      it 'personalises the email' do
        params[:message] = ""
        expect(mail.govuk_notify_personalisation).
            to eq(
              email_subject: 'New OMIC allocation',
              pom_name: params[:pom_name],
              responsibility: params[:responsibility],
              offender_name: params[:offender_name],
              nomis_offender_id: params[:offender_no],
              message: params[:message],
              url: params[:url]
                   )
      end
    end
  end

  describe 'deallocation_email' do
    let(:params) do
      {
        previous_pom_name: "Pobee-Norris, Kath",
        responsibility: "Supporting",
        previous_pom_email: "another@example.com",
        new_pom_name: "Pom, Moic",
        offender_name: "Marks, Simon",
        offender_no: "GE4595D",
        url: "http:://example.com",
        prison: "HMP Leeds"
      }
    end

    let(:mail) { described_class.deallocation_email(params) }

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
            previous_pom_name: params[:previous_pom_name],
            responsibility: params[:responsibility],
            new_pom_name: params[:new_pom_name],
            offender_name: params[:offender_name],
            nomis_offender_id: params[:offender_no],
            prison: params[:prison],
            url: params[:url]
             )
    end
  end

  describe 'deallocate_coworking_pom' do
    let(:params) do
      {
        email_address: "something@example.com",
        pom_name: "Pobee-Norris, Kath",
        secondary_pom_name: "Pom, Moic",
        nomis_offender_id: "GE4595D",
        offender_name: "Marks, Simon",
        url: "http:://example.com"
      }
    end

    let(:mail) { described_class.deallocate_coworking_pom(params) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).
          to eq 'bbdd094b-037b-424d-8b9b-ee310e291c9e'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["something@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).
          to eq(
            email_address: params[:email_address],
            pom_name: params[:pom_name],
            secondary_pom_name: params[:secondary_pom_name],
            offender_name: params[:offender_name],
            nomis_offender_id: params[:nomis_offender_id],
            url: params[:url]
             )
    end
  end

  describe 'responsibility_override_open_prison' do
    let(:params) do
      {
        prisoner_name: 'Prisoner, A',
        prisoner_number: 'A1234AA',
        responsible_pom_name: 'POM, Responsible',
        responsible_pom_email: 'responsible_pom@localhost.local',
        prison_name: 'HMP Current',
        previous_prison_name: 'HMP Previous',
        email: 'testuser@localhost.local'
      }
    end

    let(:mail) { described_class.responsibility_override_open_prison(params) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).
          to eq 'e517ddc9-5854-462e-b9a1-f67c97ad5b63'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["testuser@localhost.local"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).
        to eq(
          prisoner_name: params[:prisoner_name],
          prisoner_number: params[:prisoner_number],
          responsible_pom_name: params[:responsible_pom_name],
          responsible_pom_email: params[:responsible_pom_email],
          prison_name: params[:prison_name],
          previous_prison_name: params[:previous_prison_name]
        )
    end
  end

  describe 'manual_case_info_update' do
    let(:params) do
      {
        email_address: 'testuser@localhost.local',
        ldu_name: 'LDU1',
        offender_name: 'Prisoner, Alphabet',
        nomis_offender_id: 'A1234AA',
        offender_dob: '24 May 1984',
        prison_name: 'HMP Lockdown',
        message: "No match could be found",
        spo_notice: "This is a copy of the message sent to the LDU"
      }
    end

    let(:mail) { described_class.manual_case_info_update(params) }

    it 'sets the template' do
      expect(mail.govuk_notify_template).
      to eq '3a795dc1-6e8a-4e7b-93d7-f30813389d84'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["testuser@localhost.local"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).
      to eq(
        ldu_name: params[:ldu_name],
        offender_name: params[:offender_name],
        nomis_offender_id: params[:nomis_offender_id],
        offender_dob: params[:offender_dob],
        prison_name: params[:prison_name],
        message: params[:message],
        spo_notice: params[:spo_notice]
         )
    end
  end
end
