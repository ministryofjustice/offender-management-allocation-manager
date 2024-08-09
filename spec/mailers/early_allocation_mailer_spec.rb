require 'rails_helper'

RSpec.describe EarlyAllocationMailer, type: :mailer do
  describe 'review_early_allocation' do
    let(:params) do
      {
        prisoner_name: "Brown, James",
        start_page_link: prison_prisoner_early_allocations_path(prison_id: "LEI", prisoner_id: "T1000AA"),
        equip_guidance_link: "http://www.equip_guidance_link.html",
        email: 'to@example.com',
      }
    end

    let(:mail) { described_class.with(**params).review_early_allocation }

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

  describe 'community_early_allocation' do
    subject(:mail) { described_class.with(**params).community_early_allocation }

    let(:params) do
      {
        prisoner_name: 'TESTNAME',
        prisoner_number: '1111',
        pom_name: 'POMNAME',
        pom_email: 'pom@example.com',
        prison_name: 'PRISONMAME',
        email: 'to@example.com',
        pdf: 'FAKEPDF',
      }
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(['to@example.com'])
    end

    it 'personalises the email' do
      expect(
        mail.govuk_notify_personalisation
      ).to include(
        prisoner_name: 'TESTNAME',
        prisoner_number: '1111',
        pom_name: 'POMNAME',
        pom_email_address: 'pom@example.com',
        prison_name: 'PRISONMAME',
        link_to_document: hash_including(
          filename: "early_allocation_assessment_review_#{params[:prisoner_number]}.pdf",
          confirm_email_before_download: nil,
          retention_period: nil
        )
      )
    end
  end

  describe 'auto_early_allocation' do
    subject(:mail) { described_class.with(**params).auto_early_allocation }

    let(:params) do
      {
        prisoner_name: 'TESTNAME',
        prisoner_number: '1111',
        pom_name: 'POMNAME',
        pom_email: 'pom@example.com',
        prison_name: 'PRISONMAME',
        email: 'to@example.com',
        pdf: 'FAKEPDF',
      }
    end

    it 'sets the To address of the email using the provided user' do
      expect(mail.to).to eq(['to@example.com'])
    end

    it 'personalises the email' do
      expect(
        mail.govuk_notify_personalisation
      ).to include(
        prisoner_name: 'TESTNAME',
        prisoner_number: '1111',
        pom_name: 'POMNAME',
        pom_email_address: 'pom@example.com',
        prison_name: 'PRISONMAME',
        link_to_document: hash_including(
          filename: "early_allocation_assessment_approved_#{params[:prisoner_number]}.pdf",
          confirm_email_before_download: nil,
          retention_period: nil
        )
      )
    end
  end
end
