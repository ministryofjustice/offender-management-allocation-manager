# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, :code, presence: true

  validates :shadow_code, uniqueness: true, if: -> { nps? }
  validates :code, uniqueness: true, if: -> { nps? }
  validates :name, uniqueness: true, if: -> { nps? }

  scope :nps, -> { where('teams.code like ?', 'N%') }

  def nps?
    code&.starts_with?('N')
  end

  belongs_to :local_divisional_unit

  has_many :case_information, dependent: :restrict_with_error, counter_cache: :case_information_count
end
