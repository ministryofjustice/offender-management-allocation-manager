class EmailHistoryMailObserver
  def self.delivered_email(message)
    reference_to_event_map = {
      'email.pom.responsibility_override' => EmailHistory::RESPONSIBILITY_OVERRIDE,
      'email.community.open_prison_supporting_com_needed' => EmailHistory::OPEN_PRISON_SUPPORTING_COM_NEEDED,
      'email.community.urgent_pipeline_to_community' => EmailHistory::URGENT_PIPELINE_TO_COMMUNITY,
      'email.community.assign_com_less_than_10_months' => EmailHistory::ASSIGN_COM_LESS_THAN_10_MONTHS,
      'email.early_allocation.community_early_allocation' => EmailHistory::COMMUNITY_EARLY_ALLOCATION
    }

    if (event = reference_to_event_map[message.govuk_notify_reference]).present?
      prison = Prison.find_by(name: message.govuk_notify_personalisation[:prison_name])&.code

      nomis_offender_id = [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| message.govuk_notify_personalisation[key] }
        .find(&:itself)

      email = message.to.first

      EmailHistory.create!(event:, nomis_offender_id:, prison:, email:, name: email)
    end
  end
end
