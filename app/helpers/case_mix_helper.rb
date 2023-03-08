# frozen_string_literal: true

module CaseMixHelper
  TIER_LABELS = { tier_a: 'Tier A', tier_b: 'Tier B', tier_c: 'Tier C', tier_d: 'Tier D', tier_na: 'Tier N/A' }.freeze

  RESPONSIBILITY_LABELS = { responsible: 'Responsible', supporting: 'Supporting', coworking: 'Co-working' }.freeze

  def case_mix_key
    render 'poms/case-mix/key', labels: TIER_LABELS
  end

  def case_mix_bar_by_tiers(allocations, preserve_space_if_none: false)
    tiers = {
      tier_a: allocations.count { |a| a.tier == 'A' },
      tier_b: allocations.count { |a| a.tier == 'B' },
      tier_c: allocations.count { |a| a.tier == 'C' },
      tier_d: allocations.count { |a| a.tier == 'D' },
      tier_na: allocations.count { |a| a.tier == 'N/A' },
    }.reject { |_tier, count| count.zero? } # filter out zero-count tiers

    return '<div class="case-mix-bar"></div>'.html_safe if tiers.none? && preserve_space_if_none

    css_columns = tiers.values.map { |count|
      # Value for CSS property grid-template-columns
      %W[0 #{count}fr]
    }.join(' ')

    render 'poms/case-mix/bar', tiers: tiers, css_columns: css_columns, labels: TIER_LABELS
  end

  def case_mix_vertical_by_tiers(allocations)
    tiers = {
      tier_a: allocations.count { |a| a.tier == 'A' },
      tier_b: allocations.count { |a| a.tier == 'B' },
      tier_c: allocations.count { |a| a.tier == 'C' },
      tier_d: allocations.count { |a| a.tier == 'D' },
      tier_na: allocations.count { |a| a.tier == 'N/A' },
    }
    render 'poms/case-mix/vertical', tiers: tiers, labels: TIER_LABELS
  end

  def case_mix_bar_by_role(allocations, preserve_space_if_none: false)
    tiers = {
      responsible: allocations.count(&:pom_responsible?),
      supporting: allocations.count(&:pom_supporting?),
      coworking: allocations.count(&:coworking?),
    }.reject { |_tier, count| count.zero? } # filter out zero-count tiers

    return '<div class="case-mix-bar"></div>'.html_safe if tiers.none? && preserve_space_if_none

    css_columns = tiers.values.map { |count|
      # Value for CSS property grid-template-columns
      %W[0 #{count}fr]
    }.join(' ')

    render 'poms/case-mix/bar', tiers: tiers, css_columns: css_columns, labels: RESPONSIBILITY_LABELS
  end

  def case_mix_vertical_by_role(allocations)
    tiers = {
      responsible: allocations.count(&:pom_responsible?),
      supporting: allocations.count(&:pom_supporting?),
      coworking: allocations.count(&:coworking?),
    }
    render 'poms/case-mix/vertical', tiers: tiers, labels: RESPONSIBILITY_LABELS
  end
end
