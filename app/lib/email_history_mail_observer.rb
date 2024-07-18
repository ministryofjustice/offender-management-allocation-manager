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
      EmailHistory.create!(event:, **EmailHistoryDetailsFromMessage.new(message).as_attributes)
    end
  end

  class EmailHistoryDetailsFromMessage < SimpleDelegator
    def nomis_offender_id
      [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| govuk_notify_personalisation[key] }
        .find(&:itself)
    end
    def prison = Prison.find_by(name: govuk_notify_personalisation[:prison_name])&.code
    def email = to.first
    def name = to.first
    def as_attributes = { prison:, nomis_offender_id:, email:, name: }
  end
end
