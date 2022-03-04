class EarlyAllocationDiscretionaryForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :nomis_offender_id, :string

  validates_presence_of :nomis_offender_id, strict: true

  # Stage 1 fields - delivered as hidden fields on the form
  attribute :oasys_risk_assessment_date, :date
  EarlyAllocation::ELIGIBLE_BOOLEAN_FIELDS.each do |field|
    attribute field, :boolean
  end

  EarlyAllocation::ALL_DISCRETIONARY_FIELDS.each do |field|
    attribute field, :boolean
  end

  EarlyAllocation::DISCRETIONARY_PLAIN_BOOLEAN_FIELDS.each do |field|
    validates(field, inclusion: {
      in: [true, false],
      allow_nil: false
    })
  end

  # This field is only prompted for if extremism_separation is true
  validates(:due_for_release_in_less_than_24months, inclusion: {
    in: [true, false],
    allow_nil: false }, if: -> { extremism_separation })
end
