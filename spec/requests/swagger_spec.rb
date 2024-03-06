require 'rails_helper'

describe 'GET /swagger-ui.html', type: :request do
  it 'redirects to the Swagger UI' do
    get '/swagger-ui.html'

    expect(response).to redirect_to("/api-docs/index.html")
  end
end
