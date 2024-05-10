class Api::Handover
  def initialize(calculated_handover_date)
    @calculated_handover_date = calculated_handover_date
    @offender = @calculated_handover_date.offender
  end

  def as_json(*)
    {
      'nomsNumber' => @calculated_handover_date.nomis_offender_id,
      'handoverDate' => @calculated_handover_date.handover_date&.iso8601,
      'handoverStartDate' => @calculated_handover_date.start_date&.iso8601,
      'responsibility' => @calculated_handover_date.responsibility_text,
      **(@calculated_handover_date.com_responsible? ? com_responsibility : pom_responsibility)
    }
  end

private

  def com_responsibility
    {
      'responsibleComName' => @offender.responsible_com_name,
      'responsibleComEmail' => @offender.responsible_com_email,
      'responsiblePomName' => nil,
      'responsiblePomNomisId' => nil,
    }
  end

  def pom_responsibility
    {
      'responsibleComName' => nil,
      'responsibleComEmail' => nil,
      'responsiblePomName' => @offender.responsible_pom_name,
      'responsiblePomNomisId' => @offender.responsible_pom_nomis_id,
    }
  end
end
