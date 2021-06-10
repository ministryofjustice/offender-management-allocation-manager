# frozen_string_literal: true

class Offender < ApplicationRecord
  # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters> (all uppercase)
  validates :nomis_offender_id, format: { with: /\A[A-Z][0-9]{4}[A-Z]{2}\z/ }

  has_one :case_information, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :early_allocations,
           -> { order(created_at: :asc) },
           foreign_key: :nomis_offender_id,
           primary_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_many :allocations, inverse_of: :offender
  has_many :pom_details, through: :allocations
end
