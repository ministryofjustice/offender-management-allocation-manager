# frozen_string_literal: true

class Offender < ApplicationRecord
  validates_presence_of :nomis_offender_id

  has_one :case_information, foreign_key: :nomis_offender_id, primary_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy
end
