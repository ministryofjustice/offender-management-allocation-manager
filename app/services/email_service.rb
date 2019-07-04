# frozen_string_literal: true

class EmailService
  def self.instance(params)
    message = params[:message]
    allocation = params[:allocation]

    new(allocation, message)
  end

  def initialize(allocation, message)
    @message = message
    @allocation = allocation

    @offender = OffenderService.get_offender(@allocation[:nomis_offender_id])
    @pom = PrisonOffenderManagerService.get_pom(
      @allocation.prison,
      @allocation.primary_pom_nomis_id
    )
  end

  def send_email
    return if @pom.emails.empty?

    if @allocation.event == 'reallocate_primary_pom' && previous_pom.present?
      send_deallocation_email
    end
    deliver_new_allocation_email
  end

private

  def url
    @url ||= Rails.application.routes.url_helpers.prison_caseload_index_url(@allocation.prison)
  end

  def current_responsibility
    @current_responsibility ||= ResponsibilityService.new.
      calculate_pom_responsibility(@offender).downcase
  end

  def previous_pom
    # Check the versions (there MUST be previous records if this is a reallocation)
    # and find the first version with a primary_pom id that is not the same as the
    # allocation. That will be the POM that is notified of a reallocation.
    versions = AllocationService.get_versions_for(@allocation)

    previous = versions.first { |version|
      version.primary_pom_nomis_id != @allocation.primary_pom_nomis_id
    }
    return nil if previous.blank?

    @previous_pom ||= PrisonOffenderManagerService.get_pom(
      previous.prison,
      previous.primary_pom_nomis_id
    )
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
      url: url
    ).deliver_later
  end

  def deliver_new_allocation_email
    PomMailer.new_allocation_email(
      pom_name: @pom.first_name.capitalize,
      responsibility: current_responsibility,
      pom_email: @pom.emails.first,
      offender_name: @offender.full_name,
      offender_no: @offender.offender_no,
      message: @message,
      url: url
    ).deliver_later
  end
end
