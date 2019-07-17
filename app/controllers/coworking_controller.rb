# frozen_string_literal: true

class CoworkingController < PrisonsApplicationController
  def new
    @prisoner = offender(nomis_offender_id_from_url)

    poms = PrisonOffenderManagerService.get_poms(prison_id_from_url)
    @active_poms, @unavailable_poms = poms.partition { |pom|
      %w[active unavailable].include? pom.status
    }

    @current_pom = AllocationService.current_pom_for(
      nomis_offender_id_from_url,
      prison_id_from_url
    )
    @prison_poms = @active_poms.select{ |pom| pom.position.include?('PRO') }
    @probation_poms = @active_poms.select{ |pom| pom.position.include?('PO') }
  end

  def confirm
    @prisoner = offender(nomis_offender_id_from_url)
    @primary_pom = PrisonOffenderManagerService.get_pom(
      prison_id_from_url, primary_pom_id_from_url
    )
    @secondary_pom = PrisonOffenderManagerService.get_pom(
      prison_id_from_url, nomis_staff_id_from_url
    )

    @event = AllocationVersion::ALLOCATE_SECONDARY_POM
    @event_trigger = AllocationVersion::USER
  end

  def create; end

private

  def offender(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def nomis_offender_id_from_url
    params.require(:nomis_offender_id)
  end

  def prison_id_from_url
    params.require(:prison_id)
  end

  def nomis_staff_id_from_url
    params.require(:secondary_pom_id)
  end

  def primary_pom_id_from_url
    params.require(:primary_pom_id)
  end
end
