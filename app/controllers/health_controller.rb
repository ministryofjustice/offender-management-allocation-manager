class HealthController < ApplicationController
  def index
    render plain: 'Everything is fine.'
  end
end
