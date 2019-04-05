# frozen_string_literal: true
#
class EmailService
  def self.instance(params)
    offender = OffenderService.get_offender(params[:nomis_offender_id])
    pom = PrisonOffenderManagerService.get_pom(params[:prison], params[:nomis_staff_id])
    last_allocation = AllocationService.last_allocation(params[:nomis_offender_id])
    message = params[:message]

    new(offender, pom, last_allocation, message)
  end

  URL = Rails.application.routes.url_helpers.caseload_index_url

  def initialize(offender, pom, last_allocation, message)
    @offender = offender
    @pom = pom
    @last_allocation = last_allocation
    @message = message
  end

  def send_allocation_email
    return if @pom.emails.empty?
    send_deallocation_email if @last_allocation.present?
    send_new_allocation_email
  end

  private

  def previous_pom
    @previous_pom ||= PrisonOffenderManagerService.
      get_pom(@last_allocation[:prison], @last_allocation[:nomis_staff_id])
  end

  def current_responsibility
    @current_responsibility ||= ResponsibilityService.new.
      calculate_pom_responsibility(@offender).downcase
  end

  def send_deallocation_email
    PomMailer.deallocation_email(
      previous_pom_name: previous_pom.first_name.capitalize,
      responsibility: current_responsibility,
      previous_pom_email: previous_pom.emails.first,
      new_pom_name: @pom.full_name,
      offender_name: @offender.full_name,
      offender_no: @offender.offender_no,
      prison: PrisonService.name_for(@pom.agency_id),
      url: URL
    ).deliver_later
  end

  def send_new_allocation_email
    PomMailer.new_allocation_email(
      pom_name: @pom.first_name.capitalize,
      responsibility: current_responsibility,
      pom_email: @pom.emails.first,
      offender_name: @offender.full_name,
      offender_no: @offender.offender_no,
      message: @message,
      url: URL
    ).deliver_later
  end
end
