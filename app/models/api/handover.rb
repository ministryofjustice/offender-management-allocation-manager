class Api::Handover
  def initialize(db_model)
    @db_model = db_model
  end

  private_class_method :new

  def self.[](noms_number)
    db_model = CalculatedHandoverDate.find_by_nomis_offender_id(noms_number)
    if db_model && db_model.handover_date && db_model.responsibility
      new(db_model)
    else
      nil
    end
  end

  def noms_number
    @db_model.nomis_offender_id
  end

  def handover_date
    @db_model.handover_date
  end

  def handover_start_date
    (handover_date == @db_model.start_date) ? nil : @db_model.start_date
  end

  def responsibility
    case @db_model.responsibility
    when CalculatedHandoverDate::CUSTODY_ONLY, CalculatedHandoverDate::CUSTODY_WITH_COM then 'POM'
    when CalculatedHandoverDate::COMMUNITY_RESPONSIBLE then 'COM'
    else raise 'Invalid case value'
    end
  end

  def as_json
    {
      'noms_number' => noms_number,
      'handover_date' => handover_date.iso8601,
      'handover_start_date' => handover_start_date&.iso8601,
      'responsibility' => responsibility,
    }.compact
  end
end
