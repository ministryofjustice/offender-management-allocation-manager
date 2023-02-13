class OffenderEmailSent < ApplicationRecord
  self.table_name = 'offender_email_sent'

  belongs_to :offender, foreign_key: :nomis_offender_id
end
