# frozen_string_literal: true

class ConfirmDeletePomForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  CONFIRMATIONS = %w[yes no].freeze

  attribute :confirmation, :string
  validates :confirmation, inclusion: CONFIRMATIONS

  def confirmed?
    confirmation == 'yes'
  end
end
