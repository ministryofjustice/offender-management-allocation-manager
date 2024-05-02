# frozen_string_literal: true

class PomTask
  attr_reader :offender_name, :offender_first_name, :prison_id, :offender_number, :type, :parole_review_id

  # Full name and first name derived individually in case of situations where first name isn't easily determinable from full name.
  # @param offender An MpcOffender
  def initialize(offender, type, parole_review_id = nil)
    @offender_name = offender.full_name
    @offender_first_name = offender.first_name
    @prison_id = offender.prison_id
    @offender_number = offender.offender_no
    @type = type
    @parole_review_id = parole_review_id
  end
end
