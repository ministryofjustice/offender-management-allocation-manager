# frozen_string_literal: true

class TargetHearingDateForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :target_hearing_date, :date

  validates :target_hearing_date,
            date: { after: proc { Date.yesterday }, allow_blank: true },
            presence: true
end
