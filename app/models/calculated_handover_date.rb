# frozen_string_literal: true

class CalculatedHandoverDate < ApplicationRecord
  UNKNOWN = 'Unknown'
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
    not_inside_omic_policy: 'Not inside OMIC policy',
  }.stringify_keys.freeze

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :calculated_handover_date

  validates :nomis_offender_id, uniqueness: true

  validates :responsibility, inclusion: { in: [CUSTODY_ONLY, CUSTODY_WITH_COM, COMMUNITY_RESPONSIBLE, UNKNOWN], nil: false }
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
end
