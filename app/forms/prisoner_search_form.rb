# frozen_string_literal: true

class PrisonerSearchForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :q, :string
  validates :q, length: { minimum: 3 }

  def q=(val)
    super(val.try(:squish))
  end
end
