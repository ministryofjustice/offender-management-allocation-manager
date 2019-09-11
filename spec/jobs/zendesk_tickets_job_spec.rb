require 'rails_helper'

RSpec.describe ZendeskTicketsJob, type: :job do
  subject { described_class }

  let!(:contact) {
    ContactSubmission.create!(
      message: 'text',
      name: 'Frank',
      prison: 'Leeds',
      email_address: 'email@example.com',
      referrer: 'ref',
      user_agent: 'Mozilla',
      job_type: 'SPO'
    )
  }

  let(:client) { double(Zendesk::Client) }
  let(:zendesk_moic_api) { double(Zendesk::MOICApi) }
  let(:ticket) { double(ZendeskAPI::Ticket, save!: nil) }

  let(:url_custom_field) do
    { id: ZendeskTicketsJob::URL_FIELD, value: contact.referrer }
  end

  let(:browser_custom_field) do
    { id: ZendeskTicketsJob::BROWSER_FIELD, value: contact.user_agent }
  end

  let(:prison_custom_field) do
    { id: ZendeskTicketsJob::PRISON_FIELD, value: contact.prison }
  end

  let(:service_custom_field) do
    { id: ZendeskTicketsJob::SERVICE_FIELD, value: 'MOIC' }
  end

  let(:job_type_custom_field) do
    { id: ZendeskTicketsJob::JOB_TYPE_FIELD, value: contact.job_type }
  end

  before do
    allow(Rails.application.config).to receive(:zendesk_url).and_return('https://zendesk_api.com')
    allow(Zendesk::MOICApi).to receive(:new).and_return(zendesk_moic_api)
  end

  context 'when contact is associated to a prison' do
    it 'creates a ticket with custom fields containing the prison' do
      expect(zendesk_moic_api).
          to receive(:raise_ticket).
              with(
                description: 'text',
                requester: { email: 'email@example.com',
                             name: 'Frank' },
                tags: ['moic'],
                custom_fields: [
                   url_custom_field,
                   browser_custom_field,
                   prison_custom_field,
                   job_type_custom_field,
                   service_custom_field
                ]
              ).and_return(true)

      subject.perform_now(contact)
    end
  end

  context 'when raising a ticket is successful' do
    it 'deletes the contact submission' do
      expect(zendesk_moic_api).
          to receive(:raise_ticket).
              with(
                description: 'text',
                requester: { email: 'email@example.com',
                             name: 'Frank' },
                tags: ['moic'],
                custom_fields: [
                    url_custom_field,
                    browser_custom_field,
                    prison_custom_field,
                    job_type_custom_field,
                    service_custom_field
                ]
              ).and_return(true)

      subject.perform_now(contact)

      expect(ContactSubmission.where(email_address: 'email@example.com')).not_to exist
    end
  end

  context 'when raising a ticket is not successful' do
    it 'does not delete the contact submission' do
      allow(zendesk_moic_api).
          to receive(:raise_ticket).
              with(
                description: 'text',
                requester: { email: 'email@example.com',
                             name: 'Frank' },
                tags: ['moic'],
                custom_fields: [
                    url_custom_field,
                    browser_custom_field,
                    prison_custom_field,
                    job_type_custom_field,
                    service_custom_field
                ]
              ).and_raise(ZendeskAPI::Error::ClientError.new('Error'))

      expect { subject.perform_now(contact) }.to raise_error(ZendeskAPI::Error::ClientError)
      expect(ContactSubmission.where(email_address: 'email@example.com')).to exist
    end
  end
end
