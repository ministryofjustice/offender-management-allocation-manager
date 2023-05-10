require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.join('').to_s
  config.swagger_docs = {
    'public/openapi.yml' => {
      openapi: '3.0.3',
      info: {
        title: 'MPC/MOIC API',
        version: 'v2',
      },
      servers: [
        {
          url: '{protocol}://{defaultHost}',
          variables: {
            protocol: {
              default: :https
            },
            defaultHost: {
              default: 'dev.moic.service.justice.gov.uk'
            }
          }
        },
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: "apiKey",
            description: "A bearer token obtained from HMPPS SSO",
            name: "Authorization",
            in: "header",
          }
        },
        schemas: {
          NomsNumber: {
            type: "string",
            pattern: "^[A-Z]\\d{4}[A-Z]{2}",
            example: "G0862VO",
          },
          Status: {
            type: "object",
            properties: {
              status: { type: "string" },
              message: { type: "string" },
            },
          },
        },
      },
      paths: {}
    }
  }

  config.swagger_format = :yaml
end
