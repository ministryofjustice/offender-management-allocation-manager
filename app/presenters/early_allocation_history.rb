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
      "case_history/early_allocation/#{partial_within_window}"
    else
      "case_history/early_allocation/#{partial_outside_window}"
    end
  end

private

  def partial_within_window
    if @early_allocation.community_decision.in?([true, false]) || @early_allocation.discretionary?
      'discretionary'
    elsif @early_allocation.eligible?
      'eligible'
    else
      'not_eligible'
    end
  end

  def partial_outside_window
    if @early_allocation.eligible?
      'unsent_eligible'
    elsif @early_allocation.discretionary?
      'unsent_discretionary'
    else
      'not_eligible'
    end
  end
end
