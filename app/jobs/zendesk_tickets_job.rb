class ZendeskTicketsJob < ActiveJob::Base
  queue_as :zendesk

  # Custom ticket field IDs as configured in the MOJ Digital Zendesk account
  URL_FIELD = '23730083'.freeze
  SERVICE_FIELD = '23757677'.freeze
  BROWSER_FIELD = '23791776'.freeze
  PRISON_FIELD = '23984153'.freeze

  def perform(feedback)
    feedback.destroy! if ticket_raised!(feedback)
  end

  private

  def ticket_raised!(feedback)
    client = Zendesk::MOICClient.instance
    Zendesk::MOICApi.new(client).raise_ticket(ticket_attrs(feedback))
  end

  def ticket_attrs(feedback)
    attrs = {
        description: feedback.body,
        requester: { email: email_address_to_submit(feedback),
                     name: 'Unknown',
                     tags: ['moic'],
                     custom_fields: custom_fields(feedback)}
    }
    byebug
    attrs
  end

  def email_address_to_submit(feedback)
    feedback.email_address.presence
  end

  def custom_fields(feedback)
    attrs = [
        as_hash(URL_FIELD, feedback.referrer),
        as_hash(BROWSER_FIELD, feedback.user_agent)
    ]

    if feedback.prison_id
      attrs << as_hash(PRISON_FIELD, feedback.prison.name)
    end

    attrs
  end

  def as_hash(id, value)
    { id: id, value: value }
  end
end
