module Nomis
  class NullOffender < Nomis::Offender
    def release_date; end

    def nationality; end

    def active_booking; end
  end
end
