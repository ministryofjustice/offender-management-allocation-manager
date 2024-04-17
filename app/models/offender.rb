# frozen_string_literal: true

class Offender < ApplicationRecord
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters> (all uppercase)
  validates :nomis_offender_id, format: { with: /\A[A-Z][0-9]{4}[A-Z]{2}\z/ }

  has_one :case_information, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :early_allocations,
           -> { order(created_at: :asc) },
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_many :email_histories,
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_one :responsibility,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  has_one :calculated_handover_date,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  has_one :parole_record, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy
  has_many :parole_reviews, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_one :calculated_early_allocation_status, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :victim_liaison_officers, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_one :handover_progress_checklist, foreign_key: :nomis_offender_id

  delegate :handover_progress_complete?, to: :handover_progress_checklist, allow_nil: true

  delegate :handover_date, to: :calculated_handover_date, allow_nil: true

  def handover_progress_task_completion_data
    (handover_progress_checklist || build_handover_progress_checklist).task_completion_data
  end

  # Returns the most recent parole record (can be a future parole application), regardless of activity status and outcome.
  def most_recent_parole_review
    @most_recent_parole_review ||= parole_reviews.ordered_by_sortable_date.to_a.last
  end

  # Returns the most recent parole application if it has not yet had a hearing.
  def parole_review_awaiting_hearing
    most_recent_parole_review.no_hearing_outcome? ? most_recent_parole_review : nil
  end

  # Returns the most recent parole record that has an outcome
  def most_recent_completed_parole_review
    @most_recent_completed_parole_review ||= parole_reviews.ordered_by_sortable_date.with_hearing_outcome.to_a.last
  end

  def current_parole_review
    build_parole_review_sections unless @parole_review_sections_built
    @current_parole_review
  end

  def previous_parole_reviews
    build_parole_review_sections unless @parole_review_sections_built
    @previous_parole_reviews
  end

  # @current_parole_review is the most recent parole record and will either be
  # currently active, or will have had its hearing outcome within the last 14 days
  #
  # @previous_parole_reviews are all other parole records, those that are inactive
  # and/or had hearing outcomes more than 14 days ago.
  #
  # There are situations where parole records will be inactive and not have
  # hearing outcomes.
  def build_parole_review_sections
    @parole_review_sections_built = true
    @current_parole_review = nil
    @previous_parole_reviews = []

    parole_reviews.ordered_by_sortable_date.reverse_each do |record|
      if record.no_hearing_outcome?
        if record.active?
          @current_parole_review = record
        else
          @previous_parole_reviews << record
        end
      elsif record.hearing_outcome_received_on && record.hearing_outcome_received_on > Time.zone.today - 14.days
        @current_parole_review = record
      else
        @previous_parole_reviews << record
      end
    end
  end

  # This logic follows the rules defined here: https://dsdmoj.atlassian.net/wiki/spaces/OCM/pages/4524311161/Handover+Type+Calculation
  # Please first work through that document with a domain expert, make sure it is correct and readable, and then
  # update this algorithm to reflect it. Direct changes here without keeping that doc in sync will not be appreciated.
  def handover_type
    if case_information.nil? || calculated_handover_date.nil?
      'missing'
    elsif calculated_handover_date.reason == 'determinate_short'
      'none'
    elsif case_information.enhanced_resourcing.nil? || case_information.enhanced_resourcing?
      'enhanced'
    else
      'standard'
    end
  end
end
