class ComplexityForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::AttributeAssignment

  attribute :nomis_offender_id, :string
  attribute :complexity_level, :string

  validates_presence_of :complexity_level
end
