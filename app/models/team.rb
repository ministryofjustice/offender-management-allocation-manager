# frozen_string_literal: true

class Team < ApplicationRecord
  TEAM_LDU_CODE_REGEX = /\A[a-zA-Z0-9]+\z/.freeze

  class NpsUniquenessValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      scope = Team.nps
      if record.new_record?
        record.errors.add(attribute, :taken) if scope.find_by(attribute => value).present?
      elsif scope.where(attribute => value).where.not(id: record.id).any?
        record.errors.add(attribute, :taken)
      end
    end
  end

  validates :name, presence: true
  validates :name, nps_uniqueness: true, if: -> { nps? }

  validates :code, format: { with: TEAM_LDU_CODE_REGEX }, unless: -> { code.blank? }
  validates :code, uniqueness: true, if: -> { nps? && code.present? }

  validates :shadow_code, format: { with: TEAM_LDU_CODE_REGEX }, unless: -> { shadow_code.blank? }
  validates :shadow_code, uniqueness: true, if: -> { nps? && shadow_code.present? }

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
