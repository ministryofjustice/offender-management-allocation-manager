# frozen_string_literal: true

class Team < ApplicationRecord
  validates :name, presence: true
  validates :code, format: { with: /\A[a-zA-Z0-9]+\z/, allow_nil: true }

  validates :shadow_code, uniqueness: true, if: -> { nps? && shadow_code.present? }
  validates :code, uniqueness: true, if: -> { nps? && code.present? }

  validate do |team|
    unless team.code.present? || team.shadow_code.present?
      team.errors.add(:code, 'can\'t be blank if shadow_code is blank')
    end

    if team.name.present? && team.nps? && Team.nps.where(name: team.name).any? { |t| t.id != team.id }
      team.errors.add(:name, :taken)
    end
  end

  scope :nps, -> { where('teams.code like ?', 'N%') }

  def nps?
    code&.starts_with?('N')
  end

  # This should strictly be a non-optional association, but without it we
  # will just attach the a shadow-only team to the 'OMIC Responsibility' team.
  # Maybe that's what we should do?
  belongs_to :local_divisional_unit, optional: true

  has_many :case_information, dependent: :restrict_with_error, counter_cache: :case_information_count
end
