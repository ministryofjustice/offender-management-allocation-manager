class ZendeskTicketsJob < ActiveJob::Base
  queue_as :zendesk

  # Custom ticket field IDs as configured in the MOJ Digital Zendesk account
  URL_FIELD = '23730083'.freeze
  BROWSER_FIELD = '23791776'.freeze
  PRISON_FIELD = '23984153'.freeze

  def perform(contact)
    contact.destroy! if ticket_raised!(contact)
  end

private

  def ticket_raised!(contact)
    client = Zendesk::MOICClient.instance
    Zendesk::MOICApi.new(client).raise_ticket(ticket_attrs(contact))
  end

  def ticket_attrs(contact)
    {
      description: contact.message,
      requester: { email: contact.email_address,
                   name: contact.name,
                   job_type: contact.job_type,
                   tags: ['moic'],
                   custom_fields: custom_fields(contact) }
    }
  end

  def custom_fields(contact)
    attrs = [
        as_hash(URL_FIELD, contact.referrer),
        as_hash(BROWSER_FIELD, contact.user_agent),
        as_hash(PRISON_FIELD, contact.prison)
    ]
    attrs
  end

  def as_hash(id, value)
    { id: id, value: value }
  end
end
