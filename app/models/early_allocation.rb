# frozen_string_literal: true

class EarlyAllocation < ApplicationRecord
  before_save :record_outcome

  belongs_to :case_information,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :early_allocations

  validates_presence_of :prison, :created_by_firstname, :created_by_lastname

  # nomis_offender_ids of offenders who have assessments completed before 18 months prior to their release date, where
  # the assessment outcomes are 'discretionary' or 'eligible'
  scope :suitable_offenders_pre_referral_window, -> {
    where(created_within_referral_window: false).where.not(outcome: 'ineligible')
  }

  ELIGIBLE_BOOLEAN_FIELDS = [:convicted_under_terrorisom_act_2000,
                             :high_profile,
                             :serious_crime_prevention_order,
                             :mappa_level_3,
                             :cppc_case].freeze

  ELIGIBLE_FIELDS = [:oasys_risk_assessment_date] + ELIGIBLE_BOOLEAN_FIELDS

  DISCRETIONARY_COMMON_FIELDS = [:high_risk_of_serious_harm,
                                 :mappa_level_2,
                                 :pathfinder_process,
                                 :other_reason].freeze

  DISCRETIONARY_PLAIN_BOOLEAN_FIELDS = ([:extremism_separation] + DISCRETIONARY_COMMON_FIELDS).freeze

  DISCRETIONARY_BOOLEAN_FIELDS = (DISCRETIONARY_COMMON_FIELDS + [:due_for_release_in_less_than_24months]).freeze

  # discretionary boolean fields are all nullable(i.e. tri-state) booleans, so beware querying them.
  ALL_DISCRETIONARY_FIELDS = (DISCRETIONARY_COMMON_FIELDS + [:extremism_separation, :due_for_release_in_less_than_24months]).freeze

  validates :reason, presence: true, if: -> { discretionary? }

  # approved checkbox must be ticked for final completion
  validates :approved, inclusion: { in: [true],
                                    allow_nil: false
                                    }, if: -> { discretionary? }

  validates :community_decision,
            inclusion: { in: [true, false], allow_nil: false },
            unless: -> { new_record? }

  def eligible?
    eligible_eligible?
  end

  def ineligible?
    !eligible_eligible? && (all_discretionary_false? || (extremism_separation && !due_for_release_in_less_than_24months))
  end

  def discretionary?
    !eligible? && !ineligible?
  end

  def awaiting_community_decision?
    created_within_referral_window? && discretionary? && community_decision.nil?
  end

  def community_decision_eligible_or_automatically_eligible?
    self.eligible? || community_decision == true
  end

  def community_decision_ineligible_or_automatically_ineligible?
    self.ineligible? || community_decision == false
  end

  def assessment_date
    created_at
  end

private

  def eligible_eligible?
    # If any of the 5 eligible booleans is a yes, then early allocation answer is 'yes'
    ELIGIBLE_BOOLEAN_FIELDS.map(&method(:public_send)).any?
  end

  def all_discretionary_false?
    DISCRETIONARY_PLAIN_BOOLEAN_FIELDS.map(&method(:public_send)).none?
  end

  def record_outcome
    return self.outcome = 'eligible' if eligible?
    return self.outcome = 'ineligible' if ineligible?

    self.outcome = 'discretionary'
  end
end
