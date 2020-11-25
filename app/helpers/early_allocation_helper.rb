# frozen_string_literal: true

module EarlyAllocationHelper
  def early_allocation_status(early_allocations, offender)
    most_recent = early_allocations.last
    indicative_assessments = early_allocations.select { |ea| %w[eligible discretionary].include?(ea.outcome) }

    if early_allocations.empty?
      # No assessments done yet
      'Not assessed'

    elsif !offender.within_early_allocation_window?
      # Offender is not within referral window
      'Has saved assessments'

    elsif !most_recent.created_within_referral_window && indicative_assessments.any?
      # A previous assessment was eligible or discretionary, indicating the offender may now be eligible
      'New assessment required'

    elsif most_recent.community_decision_eligible_or_automatically_eligible?
      # Assessment was done within the 18 month referral window, and it was eligible
      'Eligible - case handover date has been updated'

    elsif most_recent.awaiting_community_decision?
      # Assessment was done within the 18 month referral window, but is awaiting a community decision
      'Discretionary - the community probation team will make a decision'

    else
      # The Early Allocation was not eligible, or the community rejected it
      'Has saved assessments'
    end
  end

  def early_allocation_action_link(early_allocations, offender, prison)
    most_recent = early_allocations.last
    start_page = prison_prisoner_early_allocations_path(prison.code, offender.offender_no)
    check_and_reassess = link_to 'Check and reassess', start_page

    if early_allocations.empty?
      # No assessment done yet
      link_to 'Start assessment', start_page

    elsif !offender.within_early_allocation_window? || !most_recent.created_within_referral_window
      # Offender is not within referral window, or the latest assessment wasn't done within the 18 month referral window
      check_and_reassess

    elsif most_recent.community_decision_eligible_or_automatically_eligible?
      # Assessment was eligible
      view_assessment = prison_prisoner_early_allocation_path(prison.code, offender.offender_no, most_recent.id)
      link_to 'View assessment', view_assessment

    elsif most_recent.awaiting_community_decision?
      # Waiting for a community decision
      record_decision = edit_prison_prisoner_latest_early_allocation_path(prison.code, offender.offender_no)
      link_to 'Record community decision', record_decision

    else
      # The Early Allocation was not eligible, or the community rejected it
      check_and_reassess
    end
  end

  def early_allocation_outcome(early_allocation)
    if early_allocation.community_decision_eligible_or_automatically_eligible?
      'Eligible'
    elsif early_allocation.discretionary? && early_allocation.community_decision.nil?
      'Waiting for community decision'
    else
      'Not eligible'
    end
  end

  def early_allocation_long_outcome(early_allocation)
    if early_allocation.community_decision_eligible_or_automatically_eligible?
      if early_allocation.created_within_referral_window?
        'Eligible - the community probation team will take responsibility for this case early'
      else
        'Eligible - assessment not sent to the community probation team'
      end
    elsif early_allocation.community_decision_ineligible_or_automatically_ineligible?
      'Not eligible'
    elsif early_allocation.created_within_referral_window?
      'Discretionary - the community probation team will make a decision'
    else
      'Discretionary - assessment not sent to the community probation team'
    end
  end

  DESCRIPTIONS = {
      convicted_under_terrorisom_act_2000: 'Convicted under Terrorism Act 2000',
      high_profile: 'Identified as \'high profile\'',
      serious_crime_prevention_order: 'Has Serious Crime Prevention Order',
      mappa_level_3: 'Requires management as a Multi-Agency Public Protection (MAPPA) level 3',
      cppc_case: 'Likely to be a Critical Public Protection Case (CPPC)',
      extremism_separation: 'Has been held in an extremism separation centre',
      high_risk_of_serious_harm: 'Presents a very high risk of serious harm',
      mappa_level_2: 'Requires management as a Multi-Agency Public Protection (MAPPA) level 2',
      pathfinder_process: 'Identified through the \'pathfinder\' process',
      other_reason: 'Other reason for consideration for early allocation to the probation team',
  }.freeze

  def pom_full_name(early_allocation)
    "#{early_allocation.created_by_lastname}, #{early_allocation.created_by_firstname}"
  end
end
