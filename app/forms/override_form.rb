# frozen_string_literal: true

class OverrideForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :override_reasons, default: -> { [] }
  attribute :more_detail, :string
  attribute :suitability_detail, :string

  validates :override_reasons,
            presence: { message: 'Select one or more reasons for not accepting the recommendation' }

  validates :more_detail,
            presence: { message: 'Please provide extra detail when Other is selected' },
            if: proc { |o| o.override_reasons&.include?('other') },
            length: { maximum: 175, too_long: 'This reason cannot be more than 175 characters' }

  validates :suitability_detail,
            presence: { message: 'Enter reason for allocating this POM' },
            if: proc { |o| o.override_reasons&.include?('suitability') },
            length: { maximum: 175, too_long: 'This reason cannot be more than 175 characters' }

  # Needed for checkbox/conditional textarea behaviour
  def override_reasons=(value)
    parsed_value =
      case value
      when String
        value.blank? ? [] : JSON.parse(value)
      else
        value
      end

    super(Array(parsed_value).compact_blank)
  rescue JSON::ParserError
    super(Array(value).compact_blank)
  end
end
