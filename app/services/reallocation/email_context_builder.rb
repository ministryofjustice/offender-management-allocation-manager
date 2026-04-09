# frozen_string_literal: true

module Reallocation
  class EmailContextBuilder
    include ApplicationHelper
    include OffenderHelper
    include PomHelper

    def build(offender:, pom:, prev_pom_name:, co_working_pom: nil)
      {
        offender_name: offender.full_name_ordered,
        prisoner_number: offender.offender_no,
        pom_name: full_name_ordered(pom),
        prev_pom_name: prev_pom_name,
        co_working_pom_name: co_working_pom.blank? ? nil : full_name_ordered(co_working_pom),
        pom_role: pom_role_needed(offender).to_s,
        ldu_name: offender.ldu_name.presence || 'Unknown',
        ldu_email: offender.ldu_email_address.presence || 'Unknown',
        com_name: unreverse_name(offender.allocated_com_name).presence || 'Unknown',
        com_email: offender.allocated_com_email.presence || 'Unknown',
        handover_start_date: format_date(offender.handover_start_date).presence || 'Unknown',
        handover_completion_date: format_date(offender.responsibility_handover_date).presence || 'Unknown',
        last_oasys_completed: format_date(last_oasys_completed(offender.offender_no)).presence || 'No OASys information',
        active_alerts: offender.active_alert_labels.join(', '),
        additional_notes: nil,
      }
    end
  end
end
