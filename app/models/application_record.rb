# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # Keep `code` attrs visible in model inspection without changing req param filtering,
  # as these are no secrets (i.e. ldu_code, prison_code, etc.)
  self.filter_attributes = filter_attributes - [:code]
end
