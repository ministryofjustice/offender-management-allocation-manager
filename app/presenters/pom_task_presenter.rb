# frozen_string_literal: true

class PomTaskPresenter
  include Rails.application.routes.url_helpers

  def self.for(pom_task)
    case pom_task.type
    when :parole_outcome_date
      ParoleOutcomeDatePomTaskPresenter.new(pom_task)
    when :early_allocation_decision
      EarlyAllocationDecisionPomTaskPresenter.new(pom_task)
    end
  end

  # @offender may be either an AllocatedOffender or MpcOffender, depending on the source of the call.
  # However, all relevant methods can be found on MpcOffender.
  delegate :offender_name, :offender_first_name, :offender_number, :prison_id, :type, :parole_review_id, to: :@pom_task

  def initialize(pom_task)
    @pom_task = pom_task
  end

  def first_name_with_ownership
    "#{offender_first_name.capitalize}#{offender_first_name.downcase[-1] == 's' ? '\'' : '\'s'}"
  end
end
