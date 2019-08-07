# frozen_string_literal: true

# This 'model' is just a raw dump of the XLSX file we get from nDelius and as such
# is not really part of our data model - although we do link to it for error cases.
# This data is loaded into case_information by the nDelius ETL process.
class DeliusData < ApplicationRecord
  before_update do |data|
    if data.tier_changed?
      DeliusData.create_new_tier_change(data.crn, data.noms_no, data.tier_was, data.tier)
    end
  end

  def omicable?
    # WPT is the first 3 chars of the ldu_code for all Welsh LDU (Local Divisional Unit).
    ldu_code.present? && ldu_code.start_with?('WPT')
  end

  def service_provider
    if provider_code.present?
      return 'CRC' if provider_code.starts_with? 'C'
      return 'NPS' if provider_code.starts_with? 'N'
    end
  end

private

  def self.create_new_tier_change(crn, noms_no, old_tier, new_tier)
    TierChange.create!(crn: crn, noms_no: noms_no, old_tier: old_tier, new_tier: new_tier)
  end
end
