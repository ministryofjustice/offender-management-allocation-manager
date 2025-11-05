# frozen_string_literal: true

class CalculatedHandoverDate < ApplicationRecord
  CUSTODY_ONLY = 'CustodyOnly'
  CUSTODY_WITH_COM = 'CustodyWithCom'
  COMMUNITY_RESPONSIBLE = 'Community'

  COM_NO_HANDOVER_DATE = new(responsibility: COMMUNITY_RESPONSIBLE, reason: :com_responsibility)

  REASONS = {
    com_responsibility: 'COM Responsibility',
    recall_case: 'Recall case',
    recall_release_soon: 'Recall case',
    recall_release_later_mappa_2_3: 'Recall case',
    recall_release_later_mappa_empty_1: 'Recall case',
    recall_release_later_no_outcome: 'Recall case',
    recall_thd_over_12_months: 'Next parole hearing more than 12 months away',
    immigration_case: 'Immigration Case',
    release_date_unknown: 'Release Date Unknown',

    thd_over_12_months: 'Next parole hearing more than 12 months away',
    parole_mappa_2_3: 'Unsuccessful parole and Mappa 2/3',
    additional_isp: 'Additional ISP',

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
    determinate_parole: 'Parole'
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

  alias_method :pom_responsible?, :custody_responsible?
  alias_method :pom_supporting?, :custody_supporting?
  alias_method :com_responsible?, :community_responsible?
  alias_method :com_supporting?, :community_supporting?

  def reason_text
    REASONS.fetch(reason, "Unknown handover reason #{reason}")
  end

  def responsibility_text
    case responsibility
    when CUSTODY_ONLY, CUSTODY_WITH_COM then 'POM'
    when COMMUNITY_RESPONSIBLE          then 'COM'
    end
  end

  def has_no_handover_dates?
    handover_date.nil? && start_date.nil?
  end

  def has_handover_dates?
    handover_date.present? && start_date.present?
  end

  attr_accessor :offender_attributes_to_archive

  class << self
    # builders
    def pom_only(**attributes) = new(responsibility: CUSTODY_ONLY, **attributes)
    def pom_with_com(**attributes) = new(responsibility: CUSTODY_WITH_COM, **attributes)
    def com(**attributes) = new(responsibility: COMMUNITY_RESPONSIBLE, **attributes)

    # Queries
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
        .where('"handover_date" - cast(:days_before as int) <= :relative_to AND :relative_to < "handover_date"',
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

  def history
    History.new(self)
  end
end
