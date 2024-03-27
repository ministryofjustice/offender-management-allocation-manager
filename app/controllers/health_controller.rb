# frozen_string_literal: true

class HealthController < ApplicationController
  def index
    render json: {
      **Health.status,
      uptime: Uptime.duration_in_seconds,
      build: {
        'buildNumber' => ENV['BUILD_NUMBER'],
        'gitRef' => ENV['GIT_REF']
      },
      version: ENV['BUILD_NUMBER']
    }
  end
end
