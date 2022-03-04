class Prison < ApplicationRecord
  validates :prison_type, presence: true
  validates :code, :name, presence: true, uniqueness: true
  has_many :pom_details, dependent: :destroy, foreign_key: :prison_code, inverse_of: :prison

  enum prison_type: { womens: 'womens', mens_open: 'mens_open', mens_closed: 'mens_closed' }

  def get_list_of_poms
    # This API call doesn't do what it says on the tin. It can return duplicate
    # staff_ids in the situation where someone has more than one role.
    poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(code)
      .select { |pom| pom.prison_officer? || pom.probation_officer? }.uniq(&:staff_id)

    details = pom_details.where(nomis_staff_id: poms.map(&:staff_id))

    poms.map { |pom| PomWrapper.new(pom, get_pom_detail(details,  pom.staff_id.to_i)) }
  end

  def get_single_pom(nomis_staff_id)
    raise ArgumentError, 'Prison#get_single_pom(nil)' if nomis_staff_id.nil?

    poms_list = get_list_of_poms
    pom = poms_list.find { |p| p.staff_id == nomis_staff_id.to_i }
    if pom.blank?
      pom_staff_ids = poms_list.map(&:staff_id)
      raise StandardError, "Failed to find POM ##{nomis_staff_id} at #{code} - list is #{pom_staff_ids}"
    end

    pom
  end

  class << self
    def active
      Prison.where(code: AllocationHistory.distinct.pluck(:prison))
    end
  end

  def offenders
    allocated + unallocated
  end

  def unfiltered_offenders
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders
    @unfiltered_offenders || OffenderService.get_offenders_in_prison(self)
  end

  def all_policy_offenders
    unfiltered_offenders.select(&:inside_omic_policy?)
  end

  def allocations
    @allocations ||= AllocationHistory.active_allocations_for_prison(code).where(nomis_offender_id: all_policy_offenders.map(&:offender_no))
  end

  delegate :allocated, to: :summary

  delegate :unallocated, to: :summary

  delegate :new_arrivals, to: :summary

  delegate :missing_info, to: :summary

private

  Summary = Struct.new :allocated, :unallocated, :new_arrivals, :missing_info, :outside_omic_policy, keyword_init: true

  def summary
    @summary ||= begin
      alloc_hash = allocations.index_by(&:nomis_offender_id)
      summary = unfiltered_offenders.group_by do |offender|
        if offender.inside_omic_policy?
          allocatable = if womens?
                          offender.probation_record.present? && offender.complexity_level.present?
                        else
                          offender.probation_record.present?
                        end
          if allocatable
            if alloc_hash.key? offender.offender_no
              :allocated
            else
              :unallocated
            end
          elsif offender.prison_arrival_date.to_date == Time.zone.today
            :new_arrival
          else
            :missing_info
          end
        else
          :outside_omic_policy
        end
      end
      Summary.new allocated: summary.fetch(:allocated, []),
                  unallocated: summary.fetch(:unallocated, []),
                  new_arrivals: summary.fetch(:new_arrival, []),
                  missing_info: summary.fetch(:missing_info, []),
                  outside_omic_policy: summary.fetch(:outside_omic_policy, [])
    end
  end

  def get_pom_detail(details, nomis_staff_id)
    details.detect { |pd| pd.nomis_staff_id == nomis_staff_id } ||
      PomDetail.find_or_create_by!(prison_code: code, nomis_staff_id: nomis_staff_id) do |pom|
        pom.working_pattern = 0.0
        pom.status = 'active'
      end
  end
end
