# frozen_string_literal: true

module OverrideHelper
  def display_override_pom(allocation)
    if allocation.recommended_pom_type == 'prison'
      'Probation POM allocated instead of recommended prison POM'
    elsif allocation.recommended_pom_type == 'probation'
      'Prison POM allocated instead of recommended probation POM'
    else
      'POM allocated without a recommendation'
    end
  end

  def display_override_details(reason, allocation)
    case reason
    when 'no_staff'
      no_staff_detail(allocation)
    when 'suitability'
      suitability_detail(allocation)
    when 'continuity'
      tag.p('- This POM has worked with the prisoner before')
    when 'other'
      tag.p('- Other reason') +
      tag.p(allocation.override_detail, class: 'app-override-reason--detail')
    end
  end

private

  def no_staff_detail(allocation)
    if allocation.recommended_pom_type.present?
      tag.p("- No available #{allocation.recommended_pom_type} POMs")
    else
      tag.p('- No available POMs of the other type')
    end
  end

  def suitability_detail(allocation)
    if allocation.recommended_pom_type == 'prison'
      tag.p('- Assessed as not suitable for a prison POM')
    elsif allocation.recommended_pom_type == 'probation'
      tag.p('- Assessed as not suitable for a probation POM')
    else
      tag.p('- Assessed as suitable for the allocated POM type')
    end + tag.p(allocation.suitability_detail, class: 'app-override-reason--detail')
  end
end
