# frozen_string_literal: true

class EarlyAllocationMailer < GovukNotifyRails::Mailer
  def auto_early_allocation(email:, prisoner_name:, prisoner_number:, prison_name:, pdf:)
    set_template('dfaeb1b1-26c3-4646-8ef4-1f0ebd18e2e7')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        prison_name: prison_name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(pdf)))

    mail(to: email)
  end

  def community_early_allocation(email:, prisoner_name:, prisoner_number:, pom_name:, pom_email:, prison_name:, pdf:)
    set_template('5e546d65-57ff-49e1-8fae-c955a7b1da80')
    set_personalisation(prisoner_name: prisoner_name,
                        prisoner_number: prisoner_number,
                        pom_name: pom_name,
                        pom_email_address: pom_email,
                        prison_name: prison_name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(pdf)))

    mail(to: email)
  end
end
