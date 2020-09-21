# frozen_string_literal: true

class ResponsibilityMailer < GovukNotifyRails::Mailer
  class EmailWrapper
    def initialize(mails)
      @mails = mails
    end

    def deliver_later
      @mails.each(&:deliver_later)
    end
  end

  def responsibility_to_custody_with_pom(emails:, prisoner_name:, prisoner_number:, prison_name:, notes:, pom_name:, pom_email:)
    set_template('d3724320-8c30-4fed-b30c-899fb89dec96')
    set_personalisation(
      prisoner_name: prisoner_name,
      prisoner_number: prisoner_number,
      prison_name: prison_name,
      notes: notes,
      responsible_pom_name: pom_name,
      responsible_pom_email: pom_email
    )
    EmailWrapper.new(emails.map { |email_address| mail(to: email_address) })
  end

  def responsibility_to_custody(emails:, prisoner_name:, prisoner_number:, prison_name:, notes:)
    set_template('baeffc72-fb55-4e63-9e5c-e27d87030446')
    set_personalisation(
      prisoner_name: prisoner_name,
      prisoner_number: prisoner_number,
      prison_name: prison_name,
      notes: notes,
    )

    EmailWrapper.new(emails.map { |email_address| mail(to: email_address) })
  end
end
