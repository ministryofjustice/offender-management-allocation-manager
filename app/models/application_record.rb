# frozen_string_literal: true

# :nocov:
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
