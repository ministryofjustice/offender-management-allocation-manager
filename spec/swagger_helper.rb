require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('').to_s
  config.swagger_docs = {
    'public/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'Allocation API',
        version: 'v1'
      },
      securityDefinitions: {
        Bearer: {
          description: "A bearer token obtained from HMPPS SSO",
          type: :apiKey,
          name: 'Authorization',
          in: :header
        }
      },
      paths: {}
    }
  }
end
