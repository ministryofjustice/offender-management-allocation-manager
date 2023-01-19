require 'rails_helper'

RSpec.describe PomMailer, type: :mailer do
  let(:further_info) do
    {
      last_oasys_completed: Time.zone.today,
      handover_start_date: Time.zone.today,
      handover_completion_date: Time.zone.today,
      com_name: 'Ben Bosh',
      com_email: 'ben@bosh.net'
    }
  end

  describe 'new_allocation_email' do
    let(:params) do
      {
        pom_name: "Pom, Moic",
        pom_email: "something@example.com",
        responsibility: "supporting",
        offender_name: "Franks, Jason",
        offender_no: "AB1234S",
        message: "This is just a test",
        url: "http:://example.com",
        further_info: further_info
      }
    end

    let(:mail) { described_class.new_allocation_email(params) }

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["something@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).to eq(
        {
          email_subject: 'New OMIC allocation',
          pom_name: params[:pom_name],
          responsibility: params[:responsibility],
          offender_name: params[:offender_name],
          nomis_offender_id: params[:offender_no],
          message: "Additional information: #{params[:message]}",
          url: params[:url]
        }.merge(further_info)
      )
    end

    context 'when no optional message has been added to the email' do
      it 'personalises the email' do
        params[:message] = ""
        expect(mail.govuk_notify_personalisation).to eq(
          {
            email_subject: 'New OMIC allocation',
            pom_name: params[:pom_name],
            responsibility: params[:responsibility],
            offender_name: params[:offender_name],
            nomis_offender_id: params[:offender_no],
            message: params[:message],
            url: params[:url]
          }.merge(further_info)
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
        prison: "Leeds (HMP)",
        further_info: further_info
      }
    end

    let(:mail) { described_class.deallocation_email(params) }

    it 'sets the template' do
      expect(mail.govuk_notify_template)
          .to eq 'cd628495-6e7a-448e-b4ad-4d49d4d8567d'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["another@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation).to eq(
        {
          email_subject: 'OMIC case reallocation',
          previous_pom_name: params[:previous_pom_name],
          responsibility: params[:responsibility],
          new_pom_name: params[:new_pom_name],
          offender_name: params[:offender_name],
          nomis_offender_id: params[:offender_no],
          prison: params[:prison],
          url: params[:url]
        }.merge(further_info)
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
      expect(mail.govuk_notify_template)
          .to eq 'bbdd094b-037b-424d-8b9b-ee310e291c9e'
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(["something@example.com"])
    end

    it 'personalises the email' do
      expect(mail.govuk_notify_personalisation)
          .to eq(
            email_address: params[:email_address],
            pom_name: params[:pom_name],
            secondary_pom_name: params[:secondary_pom_name],
            offender_name: params[:offender_name],
            nomis_offender_id: params[:nomis_offender_id],
            url: params[:url]
          )
    end
  end
end
