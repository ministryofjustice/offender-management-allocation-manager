class OffenderEmailOptOut < ApplicationRecord
  OPT_OUT_FIELDS = %i[upcoming_handover_window handover_date com_allocation_overdue].freeze

  belongs_to :offender, foreign_key: :nomis_offender_id
end
