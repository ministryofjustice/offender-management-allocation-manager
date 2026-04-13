# frozen_string_literal: true

module CaseMixHelper
  RESPONSIBILITY_LABELS = { responsible: 'Responsible', supporting: 'Supporting', coworking: 'Co-working' }.freeze

  def case_mix_key
    render 'poms/case-mix/key', labels: tier_labels
  end

  def case_mix_bar_by_tiers(allocations, preserve_space_if_none: false)
    tiers = tier_counts(allocations).reject { |_tier, count| count.zero? } # filter out zero-count tiers

    return '<div class="case-mix-bar"></div>'.html_safe if tiers.none? && preserve_space_if_none

    css_columns = tiers.values.map { |count|
      # Value for CSS property grid-template-columns
      %W[0 #{count}fr]
    }.join(' ')

    render 'poms/case-mix/bar', tiers: tiers, css_columns: css_columns, labels: tier_labels
  end

  def case_mix_vertical_by_tiers(allocations)
    render 'poms/case-mix/vertical', tiers: tier_counts(allocations), labels: tier_labels
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

private

  def tier_labels
    @tier_labels ||= CaseInformation::TIER_LEVELS
                       .index_with { "Tier #{it}" }
                       .transform_keys { "tier_#{it.downcase}".to_sym }
  end

  def tier_counts(allocations)
    CaseInformation::TIER_LEVELS.each_with_object({}) do |tier, counts|
      counts["tier_#{tier.downcase}".to_sym] = allocations.count { |allocation| allocation.tier == tier }
    end
  end
end
