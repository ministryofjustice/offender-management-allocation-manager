# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, presence: true

  validates :shadow_code, uniqueness: true, if: -> { nps? && shadow_code.present? }
  validates :code, uniqueness: true, if: -> { nps? && code.present? }
  validates :name, uniqueness: true, if: -> { nps? }

  validate do |team|
    unless team.code.present? || team.shadow_code.present?
      team.errors.add(:code, 'can\'t be blank if shadow_code is blank')
    end
  end

  scope :nps, -> { where('teams.code like ?', 'N%') }

  def nps?
    code&.starts_with?('N')
  end

  belongs_to :local_divisional_unit, optional: true

  has_many :case_information, dependent: :restrict_with_error, counter_cache: :case_information_count
end
