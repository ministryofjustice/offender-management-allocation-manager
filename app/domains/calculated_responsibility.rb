class CalculatedResponsibility
  def initialize(offender)
    @offender = offender
  end

  def result
    rules = Rules.new(
      offender: @offender,
      outcome_listener: Outcomes.new,
      handover: Handover.new(@offender)
    )
    rules.outcome
  end
end
