class EarlyAllocationDateForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  # ActiveRecord version needed to consume the multi-parameter date field
  include ActiveRecord::AttributeAssignment

  attribute :nomis_offender_id, :string

  validates_presence_of :nomis_offender_id, strict: true

  attribute :oasys_risk_assessment_date, :date

  validates :oasys_risk_assessment_date,
            presence: true,
            date: {
                before: proc { Time.zone.today },
                after: proc { Time.zone.today - 3.months },
                # validating presence, so stop date validator double-checking
                allow_nil: true
            }
end
