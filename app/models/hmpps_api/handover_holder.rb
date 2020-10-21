# frozen_string_literal: true

module HmppsApi
  module HandoverHolder
    def handover_start_date
      handover.start_date
    end

    def handover_reason
      handover.reason
    end

    def responsibility_handover_date
      handover.handover_date
    end

  private

    def handover
      @handover ||= if pom_responsibility.custody?
                      HandoverDateService.handover(self)
                    else
                      HandoverDateService::NO_HANDOVER_DATE
                    end
    end
  end
end
