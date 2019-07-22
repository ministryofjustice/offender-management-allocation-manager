module OffenderHelper
  def digital_prison_service_profile_path(offender_id)
    URI.join(
      Rails.configuration.digital_prison_service_host,
      "/offenders/#{offender_id}/quick-look"
    ).to_s
  end

  def pom_responsibility_label(offender)
    offender.pom_responsibility
  end

  # TODO: not sure about the location of either this or responsibility_handover_date.
  # They feel like 'model' methods but as yet we don't have a reason to put the code
  # anywhere but here in a view helper, nor do we really have a model to attach these
  # methods to.
  #
  # This method returns the date and the reason for the calculation
  def handover_start_date(offender)
    if offender.nps_case? && !offender.early_allocation?
      if SentenceTypeService.indeterminate_sentence?(offender.imprisonment_status)
        [offender.earliest_release_date - 8.months, 'NPS Indeterminate']
      else
        [offender.earliest_release_date - (7.months + 15.days), 'NPS Determinate']
      end
    else
      [nil, 'CRC or Early Allocation']
    end
  end

  # This method returns the date and the reason for the calculation
  def responsibility_handover_date(offender)
    if offender.nps_case?
      nps_handover_date(offender)
    else
      [crc_handover_date(offender), 'CRC']
    end
  end

private

  def crc_handover_date(offender)
    [
      offender.home_detention_curfew_eligibility_date,
      offender.conditional_release_date
    ].compact.map { |date| date - 12.weeks }.min
  end

  def nps_handover_date(offender)
    if offender.early_allocation?
      return [early_allocation_handover_date(offender), 'NPS Early']
    end

    if SentenceTypeService.indeterminate_sentence?(offender.imprisonment_status)
      [indeterminate_handover_date(offender), 'NPS Inderminate']
    elsif offender.parole_eligibility_date.present?
      [offender.parole_eligibility_date - 8.months, 'NPS Determinate Parole Case']
    elsif offender.mappa_level.blank?
      [nil, 'NPS - MAPPA missing from nDelius']
    elsif offender.mappa_level.in? [1, 0]
      [mappa1_handover_date(offender), 'NPS Determinate Mappa 1/N']
    else
      [mappa_23_handover_date(offender), 'NPS Determinate Mappa 2/3']
    end
  end

  def indeterminate_handover_date(offender)
    [
      offender.parole_eligibility_date,
      offender.tariff_date
    ].compact.map { |date| date - 8.months }.min
  end

  # There are a couple of places where we need .5 of a month - which
  # we have assumed 15.days is a reasonable compromise implementation
  def mappa_23_handover_date(offender)
    [
      offender.conditional_release_date,
      offender.automatic_release_date
    ].compact.map { |date| date - (7.months + 15.days) }.min
  end

  def mappa1_handover_date(offender)
    crd_ard = [
      offender.conditional_release_date,
      offender.automatic_release_date
    ].compact.map { |date| date - (4.months + 15.days) }.min

    [
      crd_ard,
      offender.home_detention_curfew_eligibility_date
    ].compact.min
  end

  def early_allocation_handover_date(offender)
    [
      offender.conditional_release_date,
      offender.automatic_release_date
    ].compact.map { |date| date - 15.months }.min
  end
end
