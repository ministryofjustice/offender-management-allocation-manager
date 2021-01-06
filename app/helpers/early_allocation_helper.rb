# frozen_string_literal: true

module EarlyAllocationHelper
  def early_allocation_status(early_allocation)
    if early_allocation.present?
      active_status(early_allocation)
    else
      'Not assessed'
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

private

  def active_status(early_allocation)
    if early_allocation.eligible?
      'Eligible'
    elsif early_allocation.ineligible?
      'Not eligible'
    elsif early_allocation.community_decision.nil?
      'Waiting for community decision'
    elsif early_allocation.community_decision?
      'Eligible'
    else
      'Not eligible'
    end
  end
end
