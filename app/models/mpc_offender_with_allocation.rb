class MpcOffenderWithAllocation
  delegate :offender_no, :full_name, :last_name, :earliest_release_date, :earliest_release, :latest_temp_movement_date, :allocated_com_name,
           :case_allocation, :complexity_level, :date_of_birth, :tier, :probation_record, :handover_start_date, :restricted_patient?,
           :location, :responsibility_handover_date, :pom_responsible?, :pom_supporting?, :coworking?, to: :@offender

  def initialize(offender, allocation)
    @offender = offender
    @allocation = allocation
  end

  # Annoyingly in its other incarnation this calls restructure_pom_name(allocation.primary_pom_name)
  # no idea why - I think it's some sort of legacy where maybe the pom name used to be stored in the
  # allocation the other way round i.e. first last rather than last,first - and hence we have unexecutable
  # code which we can (technically) never remove
  def allocated_pom_name
    if @allocation
      @allocation.primary_pom_name.titleize
    end
  end

  # reverse order of surname, firstname stored within case-history model.
  def formatted_pom_name
    if @allocation
      i = @allocation.primary_pom_name.index(',')
      i.nil? ? nil : (@allocation.primary_pom_name[i + 2, @allocation.primary_pom_name.length - i] << ' ' << @allocation.primary_pom_name[0, i]).titleize
    end
  end

  def allocation_date
    if @allocation
      (@allocation.primary_pom_allocated_at || @allocation.updated_at)&.to_date
    end
  end

  # this is required for sorting only
  def complexity_level_number
    ComplexityLevelHelper::COMPLEXITIES.fetch(complexity_level)
  end

  def high_complexity?
    complexity_level == 'high'
  end

  def primary_pom_allocated_at
    @allocation.primary_pom_allocated_at
  end
end