class Offenders::PrisonPolicies < SimpleDelegator
  WOMENS_POLICY_START_DATE = Date.parse(ENV.fetch('WOMENS_POLICY_START_DATE', '30/04/2021'))
  WOMENS_CUTOFF_DATE = '30/9/2022'.to_date

  WELSH_POLICY_START_DATE = Time.zone.local(2019, 2, 4).utc.to_date.freeze
  WELSH_CUTOFF_DATE = '4 May 2020'.to_date.freeze

  ENGLISH_POLICY_START_DATE = Time.zone.local(2019, 10, 1).utc.to_date
  ENGLISH_PRIVATE_CUTOFF = '1 Jun 2021'.to_date.freeze
  ENGLISH_PUBLIC_CUTOFF = '15 Feb 2021'.to_date.freeze

  # OMIC open prison rules initially piloted in HMP Prescoed for Welsh offenders entering from 19/10/2020
  PRESCOED_POLICY_START_DATE = '19/10/2020'.to_date

  # OMIC open prison rules apply to the rest of the open estate from 31/03/2021
  OPEN_PRISON_POLICY_START_DATE = '31/03/2021'.to_date

  # Offenders must have been sentenced on/after the OMIC policy start date,
  # or have a release date which is on/after the 'cutoff' date.
  def policy_case?
    (sentenced_after_policy_started? || release_after_cutoff?) && \
      (in_open_conditions? ? open_prison_rules_apply? : true)
  end

  def open_prison_rules_apply?
    (
      # Offender falls into the HMP Prescoed open prison pilot
      prison_id == PrisonService::PRESCOED_CODE &&
        prison_arrival_date >= PRESCOED_POLICY_START_DATE &&
        welsh_offender
    ) ||
    (
      # Open prison rules apply because offender arrived after the open prison policy general start date
      in_male_open_prison? && prison_arrival_date >= OPEN_PRISON_POLICY_START_DATE
    ) ||
    (
      # Open policy launched before Women's prisons – so no need to check for a 'women's open policy start date'
      in_womens_prison? && category_code == 'T'
    )
  end

  def in_womens_prison?
    PrisonService.womens_prison?(prison_id)
  end

  def in_open_conditions?
    in_male_open_prison? || (in_womens_prison? && category_code == 'T')
  end

private

  def sentenced_after_policy_started?
    sentence_start_date >= policy_start_date
  end

  def release_after_cutoff?
    earliest_release_for_handover && \
      earliest_release_for_handover.date >= policy_cutoff_date
  end

  def policy_start_date
    if in_womens_prison?
      WOMENS_POLICY_START_DATE
    elsif welsh_offender
      WELSH_POLICY_START_DATE
    else
      ENGLISH_POLICY_START_DATE
    end
  end

  def policy_cutoff_date
    if in_womens_prison?
      WOMENS_CUTOFF_DATE
    elsif welsh_offender
      WELSH_CUTOFF_DATE
    elsif hub_or_private?
      ENGLISH_PRIVATE_CUTOFF
    else
      ENGLISH_PUBLIC_CUTOFF
    end
  end

  def hub_or_private?
    PrisonService.english_hub_prison?(prison_id) ||
      PrisonService.english_private_prison?(prison_id)
  end

  def in_male_open_prison?
    PrisonService.open_prison?(prison_id)
  end
end
