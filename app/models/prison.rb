class Prison < ApplicationRecord
  has_paper_trail

  validates :prison_type, presence: true
  validates :code, :name, presence: true, uniqueness: true
  has_many :pom_details, dependent: :destroy, foreign_key: :prison_code, inverse_of: :prison

  enum :prison_type, { womens: 'womens', mens_open: 'mens_open', mens_closed: 'mens_closed' }

  scope :active, -> { where(code: AllocationHistory.distinct.pluck(:prison)) }

  def get_list_of_poms(staff_id: nil)
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(code, staff_id:)
      .select { |pom| pom.prison_officer? || pom.probation_officer? }.uniq(&:staff_id)

    details = pom_details.where(nomis_staff_id: poms.map(&:staff_id))

    poms.map { |pom| PomWrapper.new(pom, get_pom_detail(details,  pom.staff_id.to_i)) }
  end

  def get_single_pom(nomis_staff_id)
    raise ArgumentError, 'Prison#get_single_pom(nil)' if nomis_staff_id.nil?

    pom = get_list_of_poms(staff_id: nomis_staff_id).first
    if pom.nil?
      raise StandardError, "Failed to find POM ##{nomis_staff_id} at #{code}"
    end

    pom
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
    offender.case_information.present? && (womens? ? offender.complexity_level.present? : true)
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

  def get_pom_detail(details, nomis_staff_id)
    details.detect { |pd| pd.nomis_staff_id == nomis_staff_id } ||
      PomDetail.find_or_create_by!(prison_code: code, nomis_staff_id: nomis_staff_id) do |pom|
        pom.working_pattern = 0.0
        pom.status = 'active'
      end
  end
end
