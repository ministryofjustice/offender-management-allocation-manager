# frozen_string_literal: true

Kaminari.configure do |config|
  config.default_per_page = 50
  config.outer_window = 1
  config.window = 1
end
