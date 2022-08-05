# frozen_string_literal: true

class CalculatedHandoverDate < ApplicationRecord
  CUSTODY_ONLY = 'CustodyOnly'
  CUSTODY_WITH_COM = 'CustodyWithCom'
  COMMUNITY_RESPONSIBLE = 'Community'

  REASONS = {
    com_responsibility: 'COM Responsibility',
    recall_case: 'Recall case',
    immigration_case: 'Immigration Case',
    release_date_unknown: 'Release Date Unknown',
    crc_case: 'CRC Case',
    nps_early_allocation: 'NPS Early Allocation',
    nps_indeterminate: 'NPS Indeterminate',
    nps_indeterminate_open: 'NPS Indeterminate - Open conditions',
    nps_determinate_parole_case: 'NPS Determinate Parole Case',
    nps_mappa_unknown: 'NPS - MAPPA level unknown',
    nps_determinate_mappa_1_n: 'NPS Determinate Mappa 1/N',
    nps_determinate_mappa_2_3: 'NPS Determinate Mappa 2/3',
    less_than_10_months_left_to_serve: 'Less than 10 months left to serve',
    pre_omic_rules: 'Pre-OMIC rules',
  }.stringify_keys.freeze

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :calculated_handover_date

  validates :nomis_offender_id, uniqueness: true

  validates :responsibility, inclusion: { in: [CUSTODY_ONLY, CUSTODY_WITH_COM, COMMUNITY_RESPONSIBLE], nil: false }
  validates :reason, inclusion: { in: REASONS.keys, nil: false }

  alias_attribute :com_allocated_date, :start_date
  alias_attribute :com_responsible_date, :handover_date

  def custody_responsible?
    responsibility.in? [CUSTODY_WITH_COM, CUSTODY_ONLY]
  end

  def custody_supporting?
    responsibility.in? [COMMUNITY_RESPONSIBLE]
  end

  def community_responsible?
    responsibility.in? [COMMUNITY_RESPONSIBLE]
  end

  def community_supporting?
    responsibility.in? [CUSTODY_WITH_COM]
  end

  def reason_text
    REASONS.fetch(reason, "Unknown handover reason #{reason}")
  end

  class << self
    def by_offender_ids(offender_id_or_ids)
      where(nomis_offender_id: offender_id_or_ids)
    end

    # Visualization of the calculation:
    #
    # cad = com allocated date (or start_date in legacy naming)
    # d = days before handover starts that case is considered in upcoming handovers window (e.g. 56 days, or 8 weeks)
    # rd = relative-to date (defaults to "today")
    #
    # "in upcoming handover window":
    #
    # cad - d                              cad
    #   |                                   |
    #   |<----------------------------------|
    #
    # So, if rd is (cad - d) or later, and rd is less than but not equal to cad, then the
    # case is considered to be in the upcoming handover window
    def in_upcoming_handover_window(upcoming_handover_window_duration: DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION,
                                    relative_to_date: Time.zone.now.to_date)
      # TODO: start_date will be renamed to com_allocated_date when we update the schema
      where('"start_date" - :days_before <= :relative_to AND :relative_to < "start_date"',
            { days_before: upcoming_handover_window_duration, relative_to: relative_to_date })
    end

    def by_upcoming_handover(offender_ids:, upcoming_handover_window_duration: nil, relative_to_date: nil)
      handover_window_args = { upcoming_handover_window_duration: upcoming_handover_window_duration,
                               relative_to_date: relative_to_date }.compact_blank
      relation
        .by_offender_ids(offender_ids)
        .where(responsibility: CUSTODY_ONLY)
        .in_upcoming_handover_window(**handover_window_args)
    end

    def by_handover_in_progress(offender_ids:)
      relation
        .by_offender_ids(offender_ids)
        .where(responsibility: CUSTODY_WITH_COM)
    end
  end
end
