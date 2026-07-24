# frozen_string_literal: true

module PomHelper
  def format_working_pattern(pattern)
    if pattern.to_d == 1.0.to_d
      'Full time'
    else
      "Part time – #{working_pattern_to_days(pattern * 10)} per week"
    end
  end

  def working_pattern_to_days(pattern)
    ['0 days',
     '0.5 day',
     '1 day',
     '1.5 days',
     '2 days',
     '2.5 days',
     '3 days',
     '3.5 days',
     '4 days',
     '4.5 days'
    ][pattern]
  end

  def full_name(pom)
    "#{pom.last_name}, #{pom.first_name}".titleize
  end

  def full_name_ordered(pom)
    "#{pom.first_name} #{pom.last_name}".titleize
  end

  def flip_name(name)
    name.split(',').reverse.join(' ').strip
  end

  def grade(pom)
    "#{pom.position_description.split(' ').first} POM"
  end

  def opposite_pom_type(pom)
    pom.probation_officer? ? 'prison' : 'probation'
  end

  def sortable_grade(pom, recommended_pom_type)
    return grade(pom) unless recommended_pom_type

    prefix = recommended_pom_type == pom.position ? '0' : '1'
    "#{prefix} #{grade(pom)}"
  end

  def status(pom)
    {
      'active' => 'available',
      'inactive' => 'away from work',
    }.fetch(pom.status, pom.status)
  end

  def full_status(pom)
    {
      active: 'Available for new allocations',
      unavailable: 'Unavailable for new allocations',
      inactive: 'Away from work',
      deleted: 'No longer recorded as a POM at this prison',
    }.fetch(pom.status.downcase.to_sym)
  end

  def active_probation_poms(poms)
    poms.select { |pom| %w[active unavailable].include?(pom.status) && pom.probation_officer? }
  end

  def active_prison_poms(poms)
    poms.select { |pom| %w[active unavailable].include?(pom.status) && pom.prison_officer? }
  end

  def inactive_poms(poms)
    poms.select(&:inactive?)
  end

  def pom_staff_list_tab_path(pom, prison_code = nil)
    anchor = pom.in_limbo? ? 'attention_needed!top' : 'inactive_poms!top'

    if prison_code
      prison_poms_path(prison_code, anchor:)
    else
      prison_poms_path(anchor:)
    end
  end
end
