# frozen_string_literal: true

PomTaskPresenter = Struct.new :offender_name,
                              :offender_number,
                              :action_label,
                              :long_label, keyword_init: true
