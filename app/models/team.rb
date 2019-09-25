# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, :code, presence: true
end
