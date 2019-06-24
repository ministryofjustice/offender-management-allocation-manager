# frozen_string_literal: true

class DeliusData < ApplicationRecord
  def self.upsert(record)
    record.default = ''
    query = statement % record

    results = ActiveRecord::Base.connection.execute(query)
    existing_tier = results.getvalue(0, 0)

    if existing_tier.present? && existing_tier != record[:tier]
      create_new_tier_change(record[:noms_no], existing_tier, record[:tier])
    end
  end

private

  def self.create_new_tier_change(noms_no, old_tier, new_tier)
    TierChange.create!(noms_no: noms_no, old_tier: old_tier, new_tier: new_tier)
  end

  def self.statement
    <<~HEREDOC
      INSERT INTO delius_data(
        crn, pnc_no, noms_no, fullname, tier, roh_cds, offender_manager, org_private_ind, org,
        provider, provider_code, ldu, ldu_code, team, team_code, mappa, mappa_levels,
        created_at, updated_at
      )
      VALUES (
        '%<crn>s', '%<pnc_no>s', '%<noms_no>s', '%<fullname>s', '%<tier>s',
        '%<roh_cds>s', '%<offender_manager>s', '%<org_private_ind>s', '%<org>s',
        '%<provider>s', '%<provider_code>s', '%<ldu>s', '%<ldu_code>s',
        '%<team>s', '%<team_code>s', '%<mappa>s', '%<mappa_levels>s', NOW(), NOW()
      )
      ON CONFLICT(noms_no) DO UPDATE
        SET tier = EXCLUDED.tier,
            updated_at = NOW()
      RETURNING (SELECT tier FROM delius_data WHERE noms_no=noms_no)
    HEREDOC
  end
end
