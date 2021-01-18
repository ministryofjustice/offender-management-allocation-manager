# frozen_string_literal: true

class EarlyAllocationHistory
  delegate :id, :prison, :created_at, :nomis_offender_id, to: :@early_allocation

  def initialize(early_allocation)
    @early_allocation = early_allocation
  end

  def created_by_name
    "#{@early_allocation.created_by_lastname}, #{@early_allocation.created_by_firstname}"
  end

  def to_partial_path
    if @early_allocation.created_within_referral_window?
      partial_within_window
    else
      partial_outside_window
    end
  end

private

  def partial_within_window
    if @early_allocation.community_decision.in?([true, false]) || @early_allocation.discretionary?
      'ea_discretionary'
    elsif @early_allocation.eligible?
      'ea_eligible'
    else
      'ea_not_eligible'
    end
  end

  def partial_outside_window
    if @early_allocation.eligible?
      'ea_unsent_eligible'
    elsif @early_allocation.discretionary?
      'ea_unsent_discretionary'
    else
      'ea_not_eligible'
    end
  end
end
