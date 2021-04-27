# frozen_string_literal: true

class ParoleReviewDateForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveRecord::AttributeAssignment

  attribute :parole_review_date, :date

  validates :parole_review_date, date: { after: proc { Date.yesterday }, allow_nil: true }
end
