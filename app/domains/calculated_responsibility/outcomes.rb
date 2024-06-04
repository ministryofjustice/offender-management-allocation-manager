class CalculatedResponsibility::Outcomes
  def is(responsibility, reason, with_handover: nil)
    responsibility_of(responsibility, reason, with_handover:)
  end

  def com(reason, with_handover: nil)
    responsibility_of(CalculatedHandoverDate::COMMUNITY_RESPONSIBLE, reason, with_handover:)
  end

  def pom_with_com(reason, with_handover: nil)
    responsibility_of(CalculatedHandoverDate::CUSTODY_WITH_COM, reason, with_handover:)
  end

  def pom(reason, with_handover: nil)
    responsibility_of(CalculatedHandoverDate::CUSTODY_ONLY, reason, with_handover:)
  end

private

  def responsibility_of(responsibility, reason, with_handover:)
    handover = with_handover ? { start_date: with_handover.start_date, handover_date: with_handover.date } : {}

    CalculatedHandoverDate.new(responsibility:, reason:, **handover)
  end
end
