# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, :code, presence: true

  scope :nps, -> { where('teams.code like ?', 'N%') }

  belongs_to :local_divisional_unit

  has_many :case_information, dependent: :restrict_with_error, counter_cache: :case_information_count
end
