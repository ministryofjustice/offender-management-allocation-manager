module Nomis::Custody
  module CustodyApi
    def custody_client
      host = Rails.configuration.nomis_oauth_host
      Nomis::Client.new(host)
    end

    def api_deserialiser
      ApiDeserialiser.new
    end
  end
end
