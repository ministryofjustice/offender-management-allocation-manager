# frozen_string_literal: true

class LocalDivisionalUnit < ApplicationRecord
  validates :code, :name, presence: true
end
