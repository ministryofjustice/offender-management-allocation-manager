module Handover
  HandoverDates = Struct.new(:handover_date,
                             :reason,
                             keyword_init: true)
end
