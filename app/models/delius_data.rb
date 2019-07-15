# frozen_string_literal: true

class DeliusData < ApplicationRecord
  before_update do |data|
    if data.tier_changed?
      DeliusData.create_new_tier_change(data.crn, data.noms_no, data.tier_was, data.tier)
    end
  end

  # TODO: this will need changing in Rails 6 as it actually has an upsert method.
  def self.upsert(record)
    DeliusData.find_or_initialize_by(crn: record[:crn]).update(record.without(:crn))
  end

  def omicable?
    ldu_code.present? && ldu_code.start_with?('WPT')
  end

  def service_provider
    return 'CRC' if provider_code.present? && provider_code[0] == 'C'

    'NPS'
  end

private

  def self.create_new_tier_change(crn, noms_no, old_tier, new_tier)
    TierChange.create!(crn: crn, noms_no: noms_no, old_tier: old_tier, new_tier: new_tier)
  end
end
