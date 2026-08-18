# frozen_string_literal: true

require 'rake'
require_relative '../../app/models/hmpps_api/movement'

namespace :movements do
  desc 'Process recent movement events. Optionally set MOVEMENTS_LOOKBACK_DAYS=3 and/or MOVEMENTS_END_DATE=2026-08-18.'
  task process: :environment do
    lookback_days = Integer(ENV.fetch('MOVEMENTS_LOOKBACK_DAYS', 1))
    end_date = Date.parse(ENV.fetch('MOVEMENTS_END_DATE', Time.zone.yesterday.to_s))

    lookback_days.times do |offset|
      MovementsOnDateJob.perform_later((end_date - offset.days).to_s)
    end
  end
end
