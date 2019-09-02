require 'rails_helper'

RSpec.describe ZendeskTicketsJob, type: :job do
  subject { described_class }

  let!(:contact) {
    ContactSubmission.create!(
        body: 'text',
        name: 'frank',
        prison: 'Leeds',
        email_address: 'email@example.com',
        referrer: 'ref',
        user_agent: 'Mozilla',
    )
  }

  let(:client) { double(Zendesk::Client) }
  let(:zendesk_pvb_api) { double(Zendesk::MOICApi) }
  let(:ticket) { double(ZendeskAPI::Ticket, save!: nil) }
  let(:prison) { 'LEI' }

  let(:url_custom_field) do
    { id: ZendeskTicketsJob::URL_FIELD, value: 'ref' }
  end

  let(:browser_custom_field) do
    { id: ZendeskTicketsJob::BROWSER_FIELD, value: 'Mozilla' }
  end

  let(:prison_custom_field) do
    { id: ZendeskTicketsJob::PRISON_FIELD, value: prison }
  end

  before do
    set_configuration_with(:zendesk_url, 'https://zendesk_api.com')
    allow(Zendesk::MOICApi).to receive(:new).and_return(zendesk_moic_api)
  end

  context 'when contact is associated to a prison' do

    it 'creates a ticket with custom fields containing the prison' do
      byebug
      expect(zendesk_moic_api).
          to receive(:raise_ticket).
              with(
                  description: 'text',
                  requester: { email: 'email@example.com',
                               name: 'Frank',
                               role: 'SPO'},
                  custom_fields: [
                      url_custom_field,
                      browser_custom_field,
                      prison_custom_field
                  ]
              ).and_return(ticket)

      subject.perform_now(contact)
    end
  end
  
  context 'when raising a ticket is successful' do
    it 'deletes the contact submission' do
      expect(zendesk_moic_api).
          to receive(:raise_ticket).
              with(
                  description: 'text',
                  requester: { email: 'email@example.com', name: 'Jim' },
                  custom_fields: [
                      url_custom_field,
                      browser_custom_field
                  ]
              ).and_return(ticket)

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
                  requester: { email: 'email@example.com', name: 'Unknown' },
                  custom_fields: [
                      url_custom_field,
                      browser_custom_field,
                      service_custom_field
                  ]
              ).and_raise(ZendeskAPI::Error::ClientError.new('Error'))

      expect { subject.perform_now(contact) }.to raise_error(ZendeskAPI::Error::ClientError)
      expect(ContactSubmission.where(email_address: 'email@example.com')).to exist
    end
  end
end
