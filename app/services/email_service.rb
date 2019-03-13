class EmailService
  # rubocop:disable Metrics/MethodLength
  def self.send_allocation_email(params)
    offender = OffenderService.get_offender(params[:nomis_offender_id])
    pom = PrisonOffenderManagerService.get_pom(params[:prison], params[:nomis_staff_id])
    last_allocation = Allocation.where(
      nomis_offender_id: params[:nomis_offender_id],
      active: false
    ).last
    message = params[:message]
    url = Rails.configuration.allocation_manager_host + '/poms/my_caseload'

    if last_allocation.present?
      previous_pom = PrisonOffenderManagerService.
          get_pom(last_allocation[:prison], last_allocation[:nomis_staff_id])

      PomMailer.deallocation_email(
        previous_pom.first_name.capitalize,
        previous_pom.emails.first,
        pom.full_name,
        offender.full_name,
        offender.offender_no,
        PrisonService.name_for(pom.agency_id),
        url
      ).deliver_later
    end

    PomMailer.new_allocation_email(
      pom.first_name.capitalize,
      pom.emails.first,
      offender.full_name,
      offender.offender_no,
      message,
      url
    ).deliver_later
  end
  # rubocop:enable Metrics/MethodLength
end
