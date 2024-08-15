# frozen_string_literal: true

# TODO: this table is no longer used as we've moved to use
# PPUD parole data imports that creates `ParoleReview`
# records instead. It's still used in the SAR endpoint tho.
#
# TBD when is a good time to cleanup DB table and leftovers.
#
class ParoleRecord < ApplicationRecord
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :parole_record
end
