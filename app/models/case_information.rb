class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'
  validates :nomis_offender_id, presence: true
  validates :tier, presence: { message: 'must be provided' }
  validates :case_allocation, presence: { message: 'must be provided' }
end
