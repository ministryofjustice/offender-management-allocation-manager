module Nomis
  class NullOffenderDetails < Nomis::OffenderDetails
    def release_date; end

    def nationality; end

    def active_booking; end
  end
end
