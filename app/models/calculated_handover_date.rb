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

    crc_case: 'CRC Case', # legacy
    nps_early_allocation: 'NPS Early Allocation', # legacy
    nps_indeterminate: 'NPS Indeterminate', # legacy
    nps_indeterminate_open: 'NPS Indeterminate - Open conditions', # legacy
    nps_determinate_parole_case: 'NPS Determinate Parole Case', # legacy
    nps_determinate: 'NPS Determinate Case', # legacy
    nps_mappa_unknown: 'NPS - MAPPA level unknown', # legacy
    nps_determinate_mappa_1_n: 'NPS Determinate Mappa 1/N', # legacy
    nps_determinate_mappa_2_3: 'NPS Determinate Mappa 2/3', # legacy
    less_than_10_months_left_to_serve: 'Less than 10 months left to serve', # legacy
    pre_omic_rules: 'Pre-OMIC rules',

    early_allocation: 'Early Allocation',
    determinate_short: 'Determinate sentence 10 months or less',
    determinate: 'Determinate sentence more than 10 months',
    indeterminate: 'Indeterminate',
    indeterminate_open: 'Indeterminate - Open conditions',
  }.stringify_keys.freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id, offender_attributes_to_archive: :offender_attributes_to_archive }

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :calculated_handover_date

  validates :nomis_offender_id, uniqueness: true

  validates :responsibility, inclusion: { in: [CUSTODY_ONLY, CUSTODY_WITH_COM, COMMUNITY_RESPONSIBLE], nil: false }
  validates :reason, inclusion: { in: REASONS.keys, nil: false }

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

  attr_accessor :offender_attributes_to_archive

  class << self
    def by_offender_ids(offender_id_or_ids)
      where(nomis_offender_id: offender_id_or_ids)
    end

    # Visualization of the calculation:
    #
    # h = handover date
    # d = days before handover starts that case is considered in upcoming handovers window (e.g. 56 days, or 8 weeks)
    # rd = relative-to date (defaults to "today")
    #
    # "in upcoming handover window":
    #
    #  h - d                                h
    #   |                                   |
    #   |<----------------------------------|
    #
    # So, if rd is (h - d) or later, and rd is less than but not equal to h, then the
    # case is considered to be in the upcoming handover window
    def by_upcoming_handover(offender_ids:,
                             upcoming_handover_window_duration: DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION,
                             relative_to_date: Time.zone.now.to_date)
      relation
        .by_offender_ids(offender_ids)
        .where(responsibility: CUSTODY_ONLY)
        .where('"handover_date" - :days_before <= :relative_to AND :relative_to < "handover_date"',
               { days_before: upcoming_handover_window_duration, relative_to: relative_to_date })
    end

    # A handover is considered in progress once responsibility goes to the community, until the prisoner is released
    def by_handover_in_progress(offender_ids:)
      relation
        .by_offender_ids(offender_ids)
        .where(responsibility: [COMMUNITY_RESPONSIBLE])
        .where.not(handover_date: nil)
    end

    def by_com_allocation_overdue(offender_ids:, relative_to_date: Time.zone.now.to_date)
      relation
        .by_handover_in_progress(offender_ids: offender_ids)
        .joins(offender: :case_information)
        .where(offender: { case_information: { com_email: nil, com_name: nil } })
        .where(':relative_to::date >= "handover_date"::date + \'2 days\'::interval', relative_to: relative_to_date)
    end
  end
end
