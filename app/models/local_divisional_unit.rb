# frozen_string_literal: true

class LocalDivisionalUnit < ApplicationRecord
  has_many :teams, dependent: :restrict_with_error

  validates :code, :name, presence: true

  validates :code, uniqueness: true

  scope :without_email_address, -> { where(email_address: nil) }
  scope :with_email_address, -> { where.not(email_address: nil) }
end
