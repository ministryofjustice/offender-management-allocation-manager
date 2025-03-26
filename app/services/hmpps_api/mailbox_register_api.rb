module HmppsApi
  class MailboxRegisterApi
    def self.client
      host = Rails.configuration.mailbox_register_api_host
      HmppsApi::Client.new(host)
    end

    # https://manage-custody-mailbox-register-api-dev.hmpps.service.justice.gov.uk/swagger-ui/index.html
    def self.get_local_delivery_units
      client.get('/local-delivery-unit-mailboxes')
    end
  end
end
