class Prison < ApplicationRecord
  has_paper_trail

  validates :prison_type, presence: true
  validates :code, :name, presence: true, uniqueness: true

  has_many :allocations, -> { active }, class_name: "AllocationHistory", foreign_key: :prison
  has_many :pom_details, dependent: :destroy, foreign_key: :prison_code, inverse_of: :prison

  enum prison_type: { womens: 'womens', mens_open: 'mens_open', mens_closed: 'mens_closed' }

  scope :active, -> { where(code: AllocationHistory.pluck('distinct(prison)')) }

  def poms
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(code)
      .select { |pom| pom.prison_officer? || pom.probation_officer? }
      .uniq(&:staff_id)

    poms.map do |pom|
      pom_detail = PomDetail.find_or_create_new_active_by!(
        prison: self,
        nomis_staff_id: pom.staff_id
      )

      PomWrapper.new(pom, pom_detail)
    end
  end

  def pom_with_id(nomis_staff_id)
    raise ArgumentError, 'Prison#pom_with_id(nil)' if nomis_staff_id.nil?

    pom = poms.find { |p| p.staff_id == nomis_staff_id.to_i }

    raise StandardError, "Failed to find POM ##{nomis_staff_id} at #{code}" if pom.blank?

    pom
  end

  def active?
    self.class.active.pluck(:code).include?(code)
  end

  def offenders
    allocated + unallocated
  end

  def policy_offenders
    unfiltered_offenders.select(&:inside_omic_policy?)
  end

  delegate :for_pom, to: :allocations, prefix: true

  def primary_allocated_offenders
    allocated.reject(&:released?).map do |offender|
      allocation = allocation_for(offender)

      AllocatedOffender.new(allocation.primary_pom_nomis_id, allocation, offender)
    end
  end

  delegate :allocated, to: :summary
  delegate :unallocated, to: :summary
  delegate :missing_info, to: :summary
  delegate :allocation_for, to: :summary

private

  def summary
    @summary ||= AllocationsSummary.new(allocations:, offenders: policy_offenders)
  end

  def unfiltered_offenders
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders
    @unfiltered_offenders ||= OffenderService.get_offenders_in_prison(self)
  end
end
