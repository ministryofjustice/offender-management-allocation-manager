# frozen_string_literal: true

require_relative '../../app/middleware/robots_tag'
Rails.application.config.middleware.use RobotsTag
