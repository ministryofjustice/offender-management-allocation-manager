class Prison < ApplicationRecord
  has_paper_trail

  validates :prison_type, presence: true
  validates :code, :name, presence: true, uniqueness: true
  has_many :pom_details, dependent: :destroy, foreign_key: :prison_code, inverse_of: :prison

  enum :prison_type, { womens: 'womens', mens_open: 'mens_open', mens_closed: 'mens_closed' }

  scope :active, -> { where(code: AllocationHistory.distinct.pluck(:prison)) }

  def get_list_of_poms(staff_id: nil, include_deleted: false)
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(code, staff_id:)
      .select { |pom| pom.prison_officer? || pom.probation_officer? }.uniq(&:staff_id)

    details = pom_details.where(nomis_staff_id: poms.map(&:staff_id))

    result = poms.map { |pom| PomWrapper.new(pom, get_pom_detail(details, pom)) }
    include_deleted ? result : result.reject(&:deleted?)
  end

  def get_single_pom(nomis_staff_id, safe: false)
    raise ArgumentError, 'Prison#get_single_pom(nil)' if nomis_staff_id.nil?

    pom = get_list_of_poms(staff_id: nomis_staff_id, include_deleted: true).first
    if pom.nil?
      if safe
        Rails.logger.warn("event=pom_not_found,staff_id=#{nomis_staff_id},prison=#{code}")
      else
        raise StandardError, "Failed to find POM ##{nomis_staff_id} at #{code}"
      end
    end

    pom
  end

  def get_removed_poms(existing_poms:)
    existing_pom_ids = existing_poms.map(&:staff_id)

    relevant_allocations = limbo_allocations_for(existing_pom_ids)
    return [] if relevant_allocations.none?

    # POMs that have a `PomDetail` but are no longer in NOMIS
    removed_pom_details = pom_details.where.not(nomis_staff_id: existing_pom_ids)
    staff_ids_with_allocations = relevant_allocations
      .where(primary_pom_nomis_id: removed_pom_details.select(:nomis_staff_id))
      .distinct.pluck(:primary_pom_nomis_id)

    removed_poms = removed_pom_details
      .where(nomis_staff_id: staff_ids_with_allocations)
      .map { StaffMember.new(self, it.nomis_staff_id, it) }

    # "Ghost" POMs: have active allocations but no `PomDetail` record
    known_pom_ids = existing_pom_ids + pom_details.pluck(:nomis_staff_id)
    ghost_pom_ids = relevant_allocations
      .where.not(primary_pom_nomis_id: known_pom_ids)
      .distinct.pluck(:primary_pom_nomis_id)

    removed_poms + ghost_pom_ids.map { find_or_create_ghost_pom(it) }
  end

  def active?
    self.class.active.pluck(:code).include?(code)
  end

  def offenders
    allocated + unallocated
  end

  def unfiltered_offenders
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders
    @unfiltered_offenders ||= OffenderService.get_offenders_in_prison(self)
  end

  def all_policy_offenders
    unfiltered_offenders.select(&:inside_omic_policy?)
  end

  def allocations
    @allocations ||= AllocationHistory.active_allocations_for_prison(code)
      .where(nomis_offender_id: all_policy_offenders.map(&:offender_no))
  end

  delegate :for_pom, to: :allocations, prefix: true

  def primary_allocated_offenders
    alloc_hash = allocations.index_by(&:nomis_offender_id)

    allocated.select { |offender| alloc_hash.key?(offender.offender_no) && !offender.released? }.map do |offender|
      AllocatedOffender.new(alloc_hash[offender.offender_no].primary_pom_nomis_id,
                            alloc_hash.fetch(offender.offender_no), offender)
    end
  end

  def offender_allocatable?(offender)
    offender.case_information&.complete_for_allocation? && (womens? ? offender.complexity_level.present? : true)
  end

  def offender_allocated?(offender)
    @allocations_by_offender_nomis_id ||= allocations.index_by(&:nomis_offender_id)
    @allocations_by_offender_nomis_id.key?(offender.nomis_offender_id)
  end

  delegate :allocated, to: :summary
  delegate :unallocated, to: :summary
  delegate :missing_info, to: :summary

private

  def summary
    @summary ||= AllocationsSummary.new(self)
  end

  # Returns allocations for POMs not in the active list, scoped to offenders
  # still at this prison. Returns an empty relation if there are no candidates
  # (avoids the expensive `allocated` call when unnecessary)
  def limbo_allocations_for(existing_pom_ids)
    candidates = AllocationHistory.active_allocations_for_prison(code)
      .where.not(primary_pom_nomis_id: existing_pom_ids)

    return AllocationHistory.none unless candidates.exists?

    candidates.where(nomis_offender_id: allocated.map(&:offender_no))
  end

  # Creates a deleted `PomDetail` so existing flows (bulk reallocation,
  # NomisUserRolesService.remove_pom) work seamlessly
  def find_or_create_ghost_pom(nomis_staff_id)
    pom_detail = pom_details.find_or_create_by!(nomis_staff_id:) do |pd|
      pd.working_pattern = 0.0
      pd.status = 'deleted'
      Rails.logger.info("event=ghost_pom_created,staff_id=#{nomis_staff_id},prison=#{code}")
    end
    StaffMember.new(self, nomis_staff_id, pom_detail)
  rescue ActiveRecord::RecordNotUnique
    StaffMember.new(self, nomis_staff_id, pom_details.find_by!(nomis_staff_id:))
  end

  def get_pom_detail(details, pom)
    details.detect { |d| d.nomis_staff_id == pom.staff_id } ||
      PomDetail.find_or_create_by!(prison_code: code, nomis_staff_id: pom.staff_id) do |pd|
        pd.hours_per_week = 0 # TODO: decide if we want to use `pom.hours_per_week` (NOMIS hours)
        pd.status = 'active'
      end
  end
end
