module Nomis
  class NullReleaseDetails < Nomis::ReleaseDetails
    def release_date; end
  end
end
