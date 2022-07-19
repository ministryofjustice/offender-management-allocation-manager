# frozen_string_literal: true

class PomTask
  attr_reader :offender_name, :offender_first_name, :prison_id, :offender_number, :type, :parole_record_id

  # Full name and first name passed individually in case of situations where first name isn't easily determinable from full name.
  def initialize(offender_full_name, offender_first_name, prison_id, offender_no, type, parole_record_id = nil)
    @offender_name = offender_full_name
    @offender_first_name = offender_first_name
    @prison_id = prison_id
    @offender_number = offender_no
    @type = type
    @parole_record_id = parole_record_id
  end
end
