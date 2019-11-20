# frozen_string_literal: true

class PomTaskPresenter
  attr_reader :offender_name,
              :offender_number,
              :action_label,
              :long_label

  def initialize(offender_name:,
    offender_number:,
    action_label:,
    long_label:)
    @offender_name = offender_name
    @offender_number = offender_number
    @action_label = action_label
    @long_label = long_label
  end
end
