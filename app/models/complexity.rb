class Complexity
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :level, :string
  attribute :reason, :string

  validates :level, presence: true
  # This is inconsistent with other form models that specify a maximum of 175 characters as currently
  # there is no reason to set a limit
  validates :reason, presence: { message: 'Enter the reason why the level has changed' }
end
