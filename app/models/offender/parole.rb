module Offender::Parole
  extend ActiveSupport::Concern

  included do
    has_many :parole_reviews, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy
  end

  def target_hearing_date
    most_recent_parole_review&.target_hearing_date
  end

  def thd_12_or_more_months_from_now?
    target_hearing_date && target_hearing_date >= 12.months.from_now
  end

  def parole_outcome_not_release?
    most_recent_completed_parole_review&.outcome_is_not_release?
  end

  # Most recent regardless of outcome or status
  def most_recent_parole_review
    @most_recent_parole_review ||= parole_reviews.ordered_by_sortable_date.last
  end

  # Latest completed parole review regardless of when outcome was received
  def most_recent_completed_parole_review
    @most_recent_completed_parole_review ||= parole_reviews.ordered_by_sortable_date.with_hearing_outcome.last
  end

  # Latest completed parole review whose outcome was received within the last 14 days
  def current_parole_review
    @current_parole_review ||= parole_reviews.ordered_by_sortable_date.current.first
  end

  # Other non-current completed reviews
  def previous_parole_reviews
    @previous_parole_reviews ||= parole_reviews.ordered_by_sortable_date.previous.reverse_order
  end
end
