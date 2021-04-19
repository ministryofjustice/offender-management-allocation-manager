# frozen_string_literal: true

module CaseMixHelper
  CASE_MIX_TIERS = %i[a b c d na].freeze

  def case_mix_key
    render partial: 'poms/case-mix/key', locals: { tiers: CASE_MIX_TIERS }
  end

  def case_mix_bar(pom)
    tiers = {
      a: pom.allocations.count { |a| a.tier == 'A' },
      b: pom.allocations.count { |a| a.tier == 'B' },
      c: pom.allocations.count { |a| a.tier == 'C' },
      d: pom.allocations.count { |a| a.tier == 'D' },
      na: pom.allocations.count { |a| a.tier == 'N/A' },
    }.reject { |_tier, count| count.zero? } # filter out zero-count tiers

    css_columns = tiers.values.map { |count|
      # Value for CSS property grid-template-columns
      %W[0 #{count}fr]
    }.join(' ')

    render partial: 'poms/case-mix/bar', locals: { tiers: tiers, css_columns: css_columns }
  end

  def tier_label(tier)
    if tier == :na
      'Tier N/A'
    else
      "Tier #{tier.to_s.upcase}"
    end
  end
end
