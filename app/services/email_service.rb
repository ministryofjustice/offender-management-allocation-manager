class EmailService
  def self.send_allocation_email(params)
    offender = OffenderService.new.get_offender(params[:nomis_offender_id])
    pom = PrisonOffenderManagerService.get_pom(params[:prison], params[:nomis_staff_id])
    last_allocation = Allocation.where(nomis_offender_id:  params[:nomis_offender_id]).
        where(active: false).last

    if last_allocation.present?
      previous_pom = PrisonOffenderManagerService.
          get_pom(last_allocation[:prison], last_allocation[:nomis_staff_id])
      PomMailer.deallocation_email(previous_pom, pom, offender).deliver_now
    end
    PomMailer.new_allocation_email(pom, offender).deliver_now
  end
end
