# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, :code, presence: true

  scope :nps, -> { where('teams.code like ?', 'N%') }

  belongs_to :local_divisional_unit
end
