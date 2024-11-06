# frozen_string_literal: true

module SortableAllocation
  extend ActiveSupport::Concern

  included do
    attr_reader :offender, :allocation
  end

  # 'Doe, John' -> 'John Doe'
  # 'JOHN DOE'  -> 'John Doe'
  def formatted_pom_name
    return unless allocation

    allocation.primary_pom_name.split(',').reverse.map(&:strip).join(' ').titleize
  end

  def allocated_pom_role
    offender.pom_responsible? ? 'Responsible' : 'Supporting'
  end

  def complexity_level_number
    ComplexityLevelHelper::COMPLEXITIES.fetch(complexity_level)
  end

  def high_complexity?
    complexity_level == 'high'
  end

  # rubocop:disable Rails/Delegate
  def complexity_level
    offender.complexity_level
  end
  # rubocop:enable Rails/Delegate
end
