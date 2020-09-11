# frozen_string_literal: true

class LocalDivisionalUnit < ApplicationRecord
  has_many :teams, dependent: :restrict_with_error

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true, format: { with: Team::TEAM_LDU_CODE_REGEX }

  scope :without_email_address, -> { where(email_address: nil) }
  scope :with_email_address, -> { where.not(email_address: nil) }
end
