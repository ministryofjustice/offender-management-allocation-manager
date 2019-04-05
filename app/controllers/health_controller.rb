# frozen_string_literal: true

class HealthController < ApplicationController
  def index
    render plain: 'Everything is fine.'
  end
end
