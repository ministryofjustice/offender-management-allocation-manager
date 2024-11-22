module Handover
  class HandoverPeriod
    attr_reader :earliest_release_date, :reason
    
    def initialize(duration_of:, earliest_release_date:, reason:)
      @offset = duration_of
      @earliest_release_date = earliest_release_date
      @reason = reason
    end
    
    def handover_date
      @earliest_release_date - @offset if @earliest_release_date
    end
  end
end