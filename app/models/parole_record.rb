# frozen_string_literal: true

class ParoleRecord < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :parole_record

  validates_presence_of :parole_review_date
end
