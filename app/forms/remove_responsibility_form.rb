# frozen_string_literal: true

class RemoveResponsibilityForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  def self.model_name
    Responsibility.model_name
  end

  attribute :nomis_offender_id, :string
  attribute :reason_text, :string

  attr_writer :value

  validates_presence_of :reason_text
end
