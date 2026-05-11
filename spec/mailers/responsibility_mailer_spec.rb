require 'rails_helper'

RSpec.describe ResponsibilityMailer, type: :mailer do
  describe 'responsibility_to_custody' do
    let(:params) do
      {
        email: 'community@example.com',
        prisoner_name: 'Franks, Jason',
        prisoner_number: 'AB1234S',
        prison_name: 'Leeds (HMP)',
        notes: 'Useful context'
      }
    end

    let(:delivery) { described_class.with(**params).responsibility_to_custody }
    let(:mail) { delivery.message }

    it 'builds a single mail for the requested recipient' do
      aggregate_failures do
        expect(delivery).to be_a(ActionMailer::Parameterized::MessageDelivery)
        expect(mail.to).to eq(['community@example.com'])
        expect(mail.govuk_notify_reference).to eq('email.responsibility.responsibility_to_custody')
      end
    end
  end

  describe 'responsibility_to_custody_with_pom' do
    let(:params) do
      {
        email: 'pom@example.com',
        prisoner_name: 'Franks, Jason',
        prisoner_number: 'AB1234S',
        prison_name: 'Leeds (HMP)',
        notes: 'Useful context',
        pom_name: 'Pom, Moic',
        pom_email: 'pom@example.com'
      }
    end

    let(:delivery) { described_class.with(**params).responsibility_to_custody_with_pom }
    let(:mail) { delivery.message }

    it 'builds a single mail for the requested recipient' do
      aggregate_failures do
        expect(delivery).to be_a(ActionMailer::Parameterized::MessageDelivery)
        expect(mail.to).to eq(['pom@example.com'])
        expect(mail.govuk_notify_reference).to eq('email.responsibility.responsibility_to_custody_with_pom')
      end
    end
  end
end
