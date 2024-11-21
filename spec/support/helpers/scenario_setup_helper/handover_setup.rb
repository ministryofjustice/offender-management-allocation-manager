module ScenarioSetupHelper
  module HandoverSetup
    def offender_with_upcoming_handover(offender, allocated_to:, at_prison:)
      create(:allocation_history, primary_pom_nomis_id: allocated_to.staffId, prison: at_prison.code, offender:)
      create(:calculated_handover_date, :upcoming_handover, offender:)
      offender
    end
    
    def offender_with_handover_in_progress(offender, allocated_to:, at_prison:)
      create(:allocation_history, primary_pom_nomis_id: allocated_to.staffId, prison: at_prison.code, offender:)
      create(:calculated_handover_date, :handover_in_progress, offender:)
      offender
    end
    
    def offender_with_overdue_handover_tasks(offender, allocated_to:, at_prison:)
      create(:allocation_history, primary_pom_nomis_id: allocated_to.staffId, prison: prison.code, offender:)
      create(:calculated_handover_date, :handover_in_progress, offender:)
      # ensure offender has standard handover - contacted_com is a required task for standard handover
      offender.case_information.update!(enhanced_resourcing: false)
      create(:handover_progress_checklist, contacted_com: false, offender:)
      offender
    end
    
    def offender_in_handover_with_com_allocation_overdue(offender, allocated_to:, at_prison:)
      create(:allocation_history, primary_pom_nomis_id: allocated_to.staffId, prison: at_prison.code, offender:)
      create(:calculated_handover_date, :handover_in_progress, offender:)
      offender.case_information.update!(com_email: nil, com_name: nil)
      offender
    end
  end
end