# frozen_string_literal: true

class Prison
  attr_reader :code

  def initialize(prison_code)
    @code = prison_code
  end

  def offenders
    OffenderService.get_offenders_for_prison(@code)
  end

  def unfiltered_offenders
    OffenderService.get_unfiltered_offenders_for_prison(@code)
  end
end
