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
    url = Rails.application.routes.url_helpers.caseload_index_url

    if last_allocation.present?
      previous_pom = PrisonOffenderManagerService.
          get_pom(last_allocation[:prison], last_allocation[:nomis_staff_id])

      return if previous_pom.emails.empty?

      PomMailer.deallocation_email(
        previous_pom_name: previous_pom.first_name.capitalize,
        previous_pom_email: previous_pom.emails.first,
        new_pom_name: pom.full_name,
        offender_name: offender.full_name,
        offender_no: offender.offender_no,
        prison: PrisonService.name_for(pom.agency_id),
        url: url
                                   ).deliver_later
    end

    return if pom.emails.empty?

    PomMailer.new_allocation_email(
      pom_name: pom.first_name.capitalize,
      pom_email: pom.emails.first,
      offender_name: offender.full_name,
      offender_no: offender.offender_no,
      message: message,
      url: url
                                   ).deliver_later
  end
  # rubocop:enable Metrics/MethodLength
end
