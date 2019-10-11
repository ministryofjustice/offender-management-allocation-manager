# frozen_string_literal: true

class EarlyAllocation < ApplicationRecord
  validates :oasys_risk_assessment_date,
            presence: true,
            date: {
              before: proc { Time.zone.today },
              after: proc { Time.zone.today - 2.years },
              # validating presence, so stop date validator double-checking
              allow_nil: true
            }
  acts_as_gov_uk_date :oasys_risk_assessment_date

  STAGE1_BOOLEAN_FIELDS = [:convicted_under_terrorisom_act_2000,
                           :high_profile,
                           :serious_crime_prevention_order,
                           :mappa_level_3,
                           :cppc_case].freeze

  STAGE1_BOOLEAN_FIELDS.each do |field|
    validates(field, inclusion: {
                in: [true, false],
                allow_nil: false
              })
  end

  STAGE1_FIELDS = [:oasys_risk_assessment_date] + STAGE1_BOOLEAN_FIELDS

  attribute :stage2_validation, :boolean

  STAGE2_COMMON_FIELDS = [:high_risk_of_serious_harm,
                          :mappa_level_2,
                          :pathfinder_process,
                          :other_reason].freeze

  STAGE2_PLAIN_BOOLEAN_FIELDS = ([:extremism_separation] + STAGE2_COMMON_FIELDS).freeze

  STAGE2_BOOLEAN_FIELDS = (STAGE2_COMMON_FIELDS + [:due_for_release_in_less_than_24months]).freeze

  # stage2 boolean fields are all nullable(i.e. tri-state) booleans, so beware querying them.
  ALL_STAGE2_FIELDS = (STAGE2_COMMON_FIELDS + [:extremism_separation, :due_for_release_in_less_than_24months]).freeze

  STAGE2_PLAIN_BOOLEAN_FIELDS.each do |field|
    validates(field, inclusion: {
                in: [true, false],
                allow_nil: false
              },
                     if: -> { stage2_validation })
  end

  # This field is only prompted for if extremism_separation is true
  validates(:due_for_release_in_less_than_24months, inclusion: {
              in: [true, false],
              allow_nil: false }, if: -> { extremism_separation })

  attribute :stage2_complete, :boolean

  validates :reason, presence: true, if: -> { stage2_complete }

  # approved checkbox must be ticked for final completion
  validates :approved, inclusion: { in: [true],
                                    allow_nil: false
                                    }, if: -> { stage2_complete }

  def eligible?
    stage1_eligible?
  end

  def ineligible?
    !stage1_eligible? && (all_stage2_false? || (extremism_separation && !due_for_release_in_less_than_24months))
  end

  def discretionary?
    !eligible? && !ineligible?
  end

private

  def stage1_eligible?
    # If any of the 5 stage1 booleans is a yes, then early allocation answer is 'yes'
    STAGE1_BOOLEAN_FIELDS.map(&method(:public_send)).any?
  end

  def all_stage2_false?
    STAGE2_PLAIN_BOOLEAN_FIELDS.map(&method(:public_send)).none?
  end
end
