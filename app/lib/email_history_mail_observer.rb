class EmailHistoryMailObserver
  def self.delivered_email(message)
    email_history_from_message = EmailHistoryFromMessage.new(message)
    email_history_from_message.log_history_if_valid
  end

  class EmailHistoryFromMessage < SimpleDelegator
    def log_history_if_valid
      email_hsitory = EmailHistory.new(event:, prison:, nomis_offender_id:, email:, name:)
      email_hsitory.save if email_hsitory.valid?
    end

  private

    def nomis_offender_id
      [:prisoner_number, :noms_no, :nomis_offender_id]
        .map { |key| govuk_notify_personalisation[key] }
        .find(&:itself)
    end

    def event = String(govuk_notify_reference).split('.').last
    def prison = Prison.find_by(name: govuk_notify_personalisation[:prison_name])&.code
    def email = to.first
    def name = to.first
  end
end
