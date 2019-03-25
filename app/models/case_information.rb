class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'
  validates :nomis_offender_id, presence: true
  validates :omicable, presence: {
    message: 'Select yes if the prisoner’s last known address was in Wales'
  }
  validates :tier, presence: {
    message: 'Select the prisoner’s tier'
  }
  validates :case_allocation, presence: {
    message: 'Select the service provider for this case'
  }
end
