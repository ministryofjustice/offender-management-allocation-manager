# frozen_string_literal: true

class ParoleRecord < ApplicationRecord
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }
  alias_attribute :target_hearing_date, :parole_eligibility_date

  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :parole_record

  validates :target_hearing_date, presence: true
end
