# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, :code, presence: true

  belongs_to :local_divisional_unit, optional: true
end
