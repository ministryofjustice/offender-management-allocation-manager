class OffenderEmailOptOut < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id
end
