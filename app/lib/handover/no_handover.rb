module Handover
  # Nil Object variation of HandoverWindow
  class NoHandover
    attr_reader :earliest_release_date, :reason, :handover_date
    
    def initialize(earliest_release_date:, reason:)
      @earliest_release_date = earliest_release_date
      @reason = reason
      @handover_date = nil
    end
  end
end