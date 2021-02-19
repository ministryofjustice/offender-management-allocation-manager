class EarlyAllocationEligibleForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :nomis_offender_id, :string

  validates_presence_of :nomis_offender_id, strict: true

  # Stage 1 fields - delivered as hidden fields on the form
  attribute :oasys_risk_assessment_date, :date

  EarlyAllocation::ELIGIBLE_BOOLEAN_FIELDS.each do |field|
    attribute field, :boolean

    validates(field, inclusion: {
        in: [true, false],
        allow_nil: false
    })
  end
end
