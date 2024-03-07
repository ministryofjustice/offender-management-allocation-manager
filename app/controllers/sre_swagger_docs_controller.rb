# frozen_string_literal: true

class SreSwaggerDocsController < ApplicationController
  def swagger_ui
    redirect_to '/api-docs/index.html'
  end

  def open_api_json
    render json: YAML.load_file('public/openapi.yml')
  end
end
