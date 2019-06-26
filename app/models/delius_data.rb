# frozen_string_literal: true

class DeliusData < ApplicationRecord
  def self.upsert(record)
    data = record.map { |k, v| [k, DeliusData.connection.quote(v)] }.to_h
    data.default = "''"

    query = statement % data

    results = ActiveRecord::Base.connection.execute(query)
    existing_tier = results.getvalue(0, 0)

    if existing_tier.present? && existing_tier != record[:tier]
      create_new_tier_change(record[:crn], record[:noms_no], existing_tier, record[:tier])
    end
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

  def self.statement
    <<~HEREDOC
      INSERT INTO delius_data(
        crn, pnc_no, noms_no, fullname, tier, roh_cds, offender_manager, org_private_ind, org,
        provider, provider_code, ldu, ldu_code, team, team_code, mappa, mappa_levels,
        created_at, updated_at
      )
      VALUES (
        %<crn>s, %<pnc_no>s, %<noms_no>s, %<fullname>s, %<tier>s,
        %<roh_cds>s, %<offender_manager>s, %<org_private_ind>s, %<org>s,
        %<provider>s, %<provider_code>s, %<ldu>s, %<ldu_code>s,
        %<team>s, %<team_code>s, %<mappa>s, %<mappa_levels>s, NOW(), NOW()
      )
      ON CONFLICT(crn) DO UPDATE
        SET tier = EXCLUDED.tier,
            updated_at = NOW()
      RETURNING (SELECT tier FROM delius_data WHERE crn=%<crn>s)
    HEREDOC
  end
end
