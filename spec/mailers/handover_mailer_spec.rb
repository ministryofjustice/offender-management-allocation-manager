require 'rails_helper'

RSpec.describe HandoverMailer, type: :mailer do
  describe '.with' do
    it 'raises when recipient email is blank' do
      expect {
        described_class.with(email: nil, nomis_offender_id: 'A1234BC')
      }.to raise_error(HandoverMailer::InvalidRecipientEmailError, 'Missing recipient email')
    end
  end

  describe '#upcoming_handover_window' do
    subject(:mail) { described_class.with(**params).upcoming_handover_window }

    let(:params) do
      {
        email: 'pom@example.com',
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        first_name: 'Jane',
        handover_date: '13 April 2026',
        enhanced_handover: false,
        release_date: '20 April 2026'
      }
    end

    it 'sets the recipient' do
      expect(mail.to).to eq(['pom@example.com'])
    end

    it 'sets the correct template and personalisation' do
      expect(mail.govuk_notify_template).to eq('7114ad9e-e71a-4424-a884-bcc72bd1a569')
      expect(mail.govuk_notify_personalisation).to include(
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        first_name: 'Jane',
        handover_date: '13 April 2026',
        is_standard: 'yes',
        is_enhanced: 'no',
        release_date: '20 April 2026'
      )
    end
  end

  describe '#handover_date' do
    subject(:mail) { described_class.with(**params).handover_date }

    let(:params) do
      {
        email: 'pom@example.com',
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        first_name: 'Jane',
        com_name: 'Alex Smith',
        com_email: 'com@example.com',
        enhanced_handover: true,
        release_date: '20 April 2026'
      }
    end

    it 'sets the recipient' do
      expect(mail.to).to eq(['pom@example.com'])
    end

    it 'sets the correct template and personalisation' do
      expect(mail.govuk_notify_template).to eq('95ddd96c-23f9-4066-b033-d4a1d83b702e')
      expect(mail.govuk_notify_personalisation).to include(
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        first_name: 'Jane',
        com_name: 'Alex Smith',
        com_email: 'com@example.com',
        is_standard: 'no',
        is_enhanced: 'yes',
        release_date: '20 April 2026'
      )
    end
  end

  describe '#com_allocation_overdue' do
    subject(:mail) { described_class.with(**params).com_allocation_overdue }

    let(:params) do
      {
        email: 'pom@example.com',
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        handover_date: '13 April 2026',
        release_date: '20 April 2026',
        ldu_name: 'Leeds',
        ldu_email: 'ldu@example.com',
        enhanced_handover: false
      }
    end

    it 'sets the recipient' do
      expect(mail.to).to eq(['pom@example.com'])
    end

    it 'sets the correct template and personalisation' do
      expect(mail.govuk_notify_template).to eq('21d34a34-f2ec-42c2-82b3-720899b58a3b')
      expect(mail.govuk_notify_personalisation).to include(
        nomis_offender_id: 'A1234BC',
        full_name_ordered: 'Doe, Jane',
        handover_date: '13 April 2026',
        release_date: '20 April 2026',
        is_standard: 'yes',
        is_enhanced: 'no',
        ldu_information: "LDU: Leeds\nLDU email: ldu@example.com\n",
        has_ldu_email: true,
        missing_ldu_email: false
      )
    end
  end
end
