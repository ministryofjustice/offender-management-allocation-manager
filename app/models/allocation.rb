class Allocation < ApplicationRecord
  belongs_to :pom_detail, inverse_of: :allocations

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :allocations

  enum allocation_type: { primary: 'primary', coworking: 'coworking' }

  validates :pom_detail, presence: true,
            uniqueness: { scope: :offender, message: 'This POM is already allocated to that offender' }
  validates :allocation_type, inclusion: { in: allocation_types.keys }
  validates :offender, presence: true,
            uniqueness: { scope: :allocation_type, message: 'The offender already has an allocation of that type' }
end
