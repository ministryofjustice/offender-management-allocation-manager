# frozen_string_literal: true

class HealthController < ApplicationController
  def index
    render json: {
      **health_checks.status,
      uptime: uptime_timer.elapsed_seconds,
      build: {
        'buildNumber' => ENV['BUILD_NUMBER'],
        'gitRef' => ENV['GIT_REF']
      },
      version: ENV['BUILD_NUMBER']
    }
  end

private

  def uptime_timer = Rails.configuration.uptime_timer
  def health_checks = Rails.configuration.health_checks
end
