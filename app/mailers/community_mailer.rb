# frozen_string_literal: true

class CommunityMailer < GovukNotifyRails::Mailer
  def pipeline_to_community(ldu:, csv_data:)
    set_template('6e2f7565-a0e3-4fd7-b814-ee9dd5148924')
    set_personalisation(ldu_name: ldu.name,
                        link_to_document: Notifications.prepare_upload(StringIO.new(csv_data), true))

    mail(to: ldu.email_address)
  end

  def pipeline_to_community_no_handovers(ldu)
    set_template('bac3628c-aabe-4043-af11-147467720e04')
    set_personalisation(ldu_name: ldu.name)

    mail(to: ldu.email_address)
  end
end
