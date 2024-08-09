# frozen_string_literal: true

class EarlyAllocationMailer < ApplicationMailer
  def auto_early_allocation
    set_template('dfaeb1b1-26c3-4646-8ef4-1f0ebd18e2e7')

    filename = "early_allocation_assessment_approved_#{params[:prisoner_number]}.pdf"
    params[:link_to_document] = Notifications.prepare_upload(StringIO.new(params[:pdf]), filename:)
    params[:pom_email_address] = params.fetch(:pom_email)

    set_personalisation(**params.slice(:prisoner_name, :prisoner_number, :pom_name, :pom_email_address, :prison_name,
                                       :link_to_document))

    mail(to: params[:email])
  end

  def community_early_allocation
    set_template('5e546d65-57ff-49e1-8fae-c955a7b1da80')

    filename = "early_allocation_assessment_review_#{params[:prisoner_number]}.pdf"
    params[:link_to_document] = Notifications.prepare_upload(StringIO.new(params[:pdf]), filename:)
    params[:pom_email_address] = params.fetch(:pom_email)

    set_personalisation(**params.slice(:prisoner_name, :prisoner_number, :pom_name, :pom_email_address, :prison_name,
                                       :link_to_document))

    mail(to: params.fetch(:email))
  end

  def review_early_allocation
    set_template('502e057c-a875-4653-9b33-63dcfd33e582')
    set_personalisation(**params.slice(:prisoner_name, :prisoner_number, :prison_name, :start_page_link, :equip_guidance_link))
    mail(to: params.fetch(:email))
  end
end
