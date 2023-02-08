# frozen_string_literal: true

module PomHelper
  def format_working_pattern(pattern)
    if pattern.to_d == 1.0.to_d
      'Full time'
    else
      "Part time – #{pattern}"
    end
  end

  def working_pattern_to_days(pattern)
    ['',
     'half a day',
     'one day',
     'one and a half days',
     'two days',
     'two and a half days',
     'three days',
     'three and a half days',
     'four days',
     'four and a half days'
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

  def full_grade(pom)
    "#{pom.position_description.split(' ').first} Officer POM"
  end

  def status(pom)
    # we are now displaying 'Available', instead of 'Active' which is stored in the database
    pom.status == 'active' ? 'available' : pom.status
  end

  def full_status(pom)
    {
      active: 'Active: available for new allocations',
      inactive: 'Inactive',
      unavailable: 'Unavailable for new allocations'
    }.fetch(pom.status.downcase.to_sym)
  end

  def active_probation_poms(poms)
    poms.select { |pom| %w[active unavailable].include?(pom.status) && pom.probation_officer? }
  end

  def active_prison_poms(poms)
    poms.select { |pom| %w[active unavailable].include?(pom.status) && pom.prison_officer? }
  end

  def inactive_poms(poms)
    poms.reject { |pom| %w[active unavailable].include? pom.status }
  end
end
