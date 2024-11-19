# frozen_string_literal: true

# This class is an adapter designed to prevent clients having to know whether
# a field lives in the allocation or sentence details when both are returned
# e.g. when fetching allocations
#
class AllocatedOffender
  include SortableAllocation

  delegate :first_name, :last_name, :full_name_ordered, :full_name,
           :earliest_release_date, :earliest_release, :tariff_date, :release_date,
           :in_upcoming_handover_window?,
           :indeterminate_sentence?, :prison_id, :target_hearing_date, :parole_eligibility_date, :allocated_com_email,
           :handover_start_date, :responsibility_handover_date, :allocated_com_name, :has_com?, :enhanced_handover?,
           :offender_no, :sentence_start_date, :tier, :location, :latest_temp_movement_date,
           :restricted_patient?, :handover_progress_task_completion_data, :handover_progress_complete?,
           :ldu_name, :ldu_email_address, :model, :released?,
           :case_information, :home_detention_curfew_actual_date, :home_detention_curfew_eligibility_date,
           :conditional_release_date, :automatic_release_date,
           :earliest_release_for_handover, :handover_type,
           :early_allocation?, :licence_expiry_date, :approaching_parole?, :next_parole_date, :next_parole_date_type,
           :pom_tasks, :com_allocation_days_overdue, :handover_date, to: :@offender
  delegate :last_name, to: :offender, prefix: true
  delegate :updated_at, :nomis_offender_id, :primary_pom_allocated_at, :prison, :primary_pom_nomis_id, :primary_pom_name,
           to: :@allocation
  delegate :full_name_ordered, to: :staff_member, prefix: true

  attr_reader :offender

  COMPLEXITIES = { 'high' => 3, 'medium' => 2, 'low' => 1 }.freeze

  def initialize(staff_id, allocation, offender)
    @staff_id = staff_id
    @allocation = allocation
    @offender = offender
  end

  # check for changes in the last week where the target value
  # (item[1] in the array) is our staff_id
  def new_case?
    @allocation.new_case_for? @staff_id
  end

  def pom_responsible?
    @offender.pom_responsible? if @allocation.primary_pom_nomis_id == @staff_id
  end

  def pom_supporting?
    @offender.pom_supporting? if @allocation.primary_pom_nomis_id == @staff_id
  end

  def coworking?
    @allocation.secondary_pom_nomis_id == @staff_id
  end

  def staff_member
    StaffMember.new(Prison.find(prison_id), @staff_id)
  end

  def latest_oasys_date
    @latest_oasys_date ||= HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(nomis_offender_id)
  end

  class << self
    def all
      prisons = Prison.all
      Enumerator.new do |yielder|
        prisons.each do |prison|
          prison.primary_allocated_offenders.each { |o| yielder.yield o }
        end
      end
    end
  end
end
