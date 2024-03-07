require 'rails_helper'

describe 'Swagger Documentation surfaced for SRE discoverability' do
  describe 'GET /swagger-ui.html' do
    it 'redirects to the Swagger UI' do
      get '/swagger-ui.html'

      expect(response).to redirect_to("/api-docs/index.html")
    end
  end

  describe 'GET /v3/api-docs' do
    it 'renders the openapi.yml in json format' do
      get '/v3/api-docs'

      expect(response.body).to eq(YAML.load_file('public/openapi.yml').to_json)
    end
  end
end
