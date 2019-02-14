class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'
  validates :nomis_offender_id, :tier, :case_allocation, presence: true
end
