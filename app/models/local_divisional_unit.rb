# frozen_string_literal: true

class LocalDivisionalUnit < ApplicationRecord
  validates :code, :name, presence: true
  has_many :teams, dependent: :destroy

  scope :without_email_address, -> { where(email_address: nil) }
end
