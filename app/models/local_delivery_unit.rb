# frozen_string_literal: true

# This is the new (2021) LDU - Local Delivery Unit.
# The old (incorrectly named) one will be removed in February 2021 after the PDU/LDU go live
class LocalDeliveryUnit < ApplicationRecord
  VALID_COUNTRIES = ['England', 'Wales'].freeze
  CODE_REGEX = /\A[a-zA-Z0-9]+\z/

  auto_strip_attributes :code, :name, :email_address

  validates :country, inclusion: { in: VALID_COUNTRIES }
  validates :code, presence: true, uniqueness: true, format: { with: CODE_REGEX }
  validates :name, presence: true
  validates :email_address,  presence: true, 'valid_email_2/email': true

  scope :enabled, -> { where(enabled: true) }

  has_many :case_information, dependent: :restrict_with_exception
end
