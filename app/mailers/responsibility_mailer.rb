# frozen_string_literal: true

class ResponsibilityMailer < ApplicationMailer
  def responsibility_to_custody_with_pom
    email, prisoner_name, prisoner_number, prison_name, notes, pom_name, pom_email = params.values_at(:email, :prisoner_name, :prisoner_number, :prison_name, :notes, :pom_name, :pom_email)
    set_template('d3724320-8c30-4fed-b30c-899fb89dec96')
    set_personalisation(
      prisoner_name: prisoner_name,
      prisoner_number: prisoner_number,
      prison_name: prison_name,
      notes: notes,
      responsible_pom_name: pom_name,
      responsible_pom_email: pom_email
    )
    mail(to: email)
  end

  def responsibility_to_custody
    email, prisoner_name, prisoner_number, prison_name, notes = params.values_at(:email, :prisoner_name, :prisoner_number, :prison_name, :notes)
    set_template('baeffc72-fb55-4e63-9e5c-e27d87030446')
    set_personalisation(
      prisoner_name: prisoner_name,
      prisoner_number: prisoner_number,
      prison_name: prison_name,
      notes: notes,
    )

    mail(to: email)
  end
end
