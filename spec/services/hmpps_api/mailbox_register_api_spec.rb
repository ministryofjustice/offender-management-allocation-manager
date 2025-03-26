# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmppsApi::MailboxRegisterApi do
  describe '.get_local_delivery_units' do
    it 'returns all the LDUs' do
      response = [
        { "id" => "06b84bb5-f925-4b34-a964-5c29e337dc2e", "unitCode" => "12345", "areaCode" => "45678", "emailAddress" => "test@example.com", "country" => "UK", "name" => "Test LDU", "createdAt" => "2025-02-05T14:32:20.340651Z", "updatedAt" => "2025-02-06T11:29:34.838613Z" },
        { "id" => "444e537b-8e20-46a7-94b5-8985e73c3e90", "unitCode" => "444", "areaCode" => "555", "emailAddress" => "test2@example.com", "country" => "Wales", "name" => "Another one", "createdAt" => "2025-02-06T11:29:54.652923Z", "updatedAt" => "2025-02-06T11:29:54.652943Z" }
      ]

      stub_request(:get, "#{Rails.configuration.mailbox_register_api_host}/local-delivery-unit-mailboxes")
        .to_return(body: response.to_json)

      expect(described_class.get_local_delivery_units).to eq(response)
    end
  end
end
