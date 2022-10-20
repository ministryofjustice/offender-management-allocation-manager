module Handover
  class HandoverDateCalculationError < HandoverError
    def initialize(msg = nil, nomis_offender_id:)
      super(msg)
      @nomis_offender_id = nomis_offender_id
    end

    attr_reader :nomis_offender_id
  end
end
