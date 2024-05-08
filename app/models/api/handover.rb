class Api::Handover
  def initialize(calculated_handover_date)
    @calculated_handover_date = calculated_handover_date
  end

  def as_json(*)
    {
      'nomsNumber' => @calculated_handover_date.nomis_offender_id,
      'handoverDate' => @calculated_handover_date.handover_date&.iso8601,
      'handoverStartDate' => @calculated_handover_date.start_date&.iso8601,
      'responsibility' => @calculated_handover_date.responsibility_text,
    }
  end
end
