module Handover
  HandoverDates = Struct.new(:handover_date,
                             :com_responsible_date,
                             :reason,
                             keyword_init: true)
end
