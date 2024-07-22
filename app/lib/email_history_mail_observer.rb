class EmailHistoryMailObserver
  EVENT_FOR_REFERENCE = {
    'email.pom.responsibility_override' => EmailHistory::RESPONSIBILITY_OVERRIDE,
    'email.community.open_prison_supporting_com_needed' => EmailHistory::OPEN_PRISON_SUPPORTING_COM_NEEDED,
    'email.community.urgent_pipeline_to_community' => EmailHistory::URGENT_PIPELINE_TO_COMMUNITY,
    'email.community.assign_com_less_than_10_months' => EmailHistory::ASSIGN_COM_LESS_THAN_10_MONTHS,
    'email.early_allocation.community_early_allocation' => EmailHistory::COMMUNITY_EARLY_ALLOCATION,
    'email.early_allocation.auto_early_allocation' => EmailHistory::AUTO_EARLY_ALLOCATION,
    'email.early_allocation.review_early_allocation' => EmailHistory::SUITABLE_FOR_EARLY_ALLOCATION,
  }.freeze

  def self.delivered_email(message)
    email_history_details = EmailHistoryDetails.new(message)

    if email_history_details.event.present?
      EmailHistory.create!(**email_history_details.as_attribtes)
    end
  end

  class EmailHistoryDetails < SimpleDelegator
    def as_attribtes = { event:, nomis_offender_id:, prison:, email:, name: }
    def event = EVENT_FOR_REFERENCE[govuk_notify_reference]
    def prison = Prison.find_by(name: govuk_notify_personalisation[:prison_name])&.code
    def email = to.first
    def name = govuk_notify_personalisation.fetch(:email_history_name, email)

    def nomis_offender_id
      [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| govuk_notify_personalisation[key] }
        .find(&:itself)
    end
  end
end
