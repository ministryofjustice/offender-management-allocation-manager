class Prison < ApplicationRecord
  validates :prison_type, presence: true
  validates :code, :name, presence: true, uniqueness: true

  enum prison_type: { womens: 'womens', mens_open: 'mens_open', mens_closed: 'mens_closed' }

  class << self
    def active
      Prison.where(code: Allocation.distinct.pluck(:prison))
    end
  end

  def offenders
    allocated + unallocated
  end

  def all_policy_offenders
    OffenderEnumerator.new(code).select(&:inside_omic_policy?)
  end

  def unfiltered_offenders
    # Returns all offenders at the provided prison, and does not
    # filter out under 18s or non-sentenced offenders
    OffenderEnumerator.new(code)
  end

  def allocations
    @allocations ||= Allocation.active_allocations_for_prison(code).where(nomis_offender_id: all_policy_offenders.map(&:offender_no))
  end

  def allocated
    summary.allocated
  end

  def unallocated
    summary.unallocated
  end

  def new_arrivals
    summary.new_arrivals
  end

  def missing_info
    summary.missing_info
  end

private

  Summary = Struct.new :allocated, :unallocated, :new_arrivals, :missing_info, :outside_omic_policy, keyword_init: true

  def summary
    alloc_hash = allocations.index_by(&:nomis_offender_id)
    @summary ||= begin
      summary = unfiltered_offenders.group_by do |offender|
        if offender.inside_omic_policy?
          allocatable = if womens?
                          offender.has_case_information? && offender.complexity_level.present?
                        else
                          offender.has_case_information?
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
      allocated = summary.fetch(:allocated, []).map do |o|
        a = alloc_hash.fetch(o.offender_no)
        AllocatedOffender.new(a.primary_pom_nomis_id, a, o)
      end
      Summary.new allocated: allocated,
                  unallocated: summary.fetch(:unallocated, []),
                  new_arrivals: summary.fetch(:new_arrival, []),
                  missing_info: summary.fetch(:missing_info, []),
                  outside_omic_policy: summary.fetch(:outside_omic_policy, [])
    end
  end

  class OffenderEnumerator
    include Enumerable
    FETCH_SIZE = 200 # How many records to fetch from nomis at a time

    def initialize(prison)
      @prison = prison
    end

    def each
      first_page = HmppsApi::PrisonApi::OffenderApi.list(
        @prison,
        0,
        page_size: FETCH_SIZE
      )
      offenders = first_page.data
      enrich_offenders(offenders)
      offenders.each { |offender| yield offender }

      1.upto(first_page.total_pages - 1).each do |page_number|
        offenders = HmppsApi::PrisonApi::OffenderApi.list(
          @prison,
          page_number,
          page_size: FETCH_SIZE
        ).data

        enrich_offenders(offenders)

        offenders.each { |offender| yield offender }
      end
    end

  private

    def enrich_offenders(offenders)
      nomis_ids = offenders.map(&:offender_no)
      mapped_tiers = CaseInformationService.get_case_information(nomis_ids)

      offenders.each { |offender|
        case_info_record = mapped_tiers[offender.offender_no]
        offender.load_case_information(case_info_record)
      }
      HmppsApi::PrisonApi::OffenderApi.add_arrival_dates(offenders)
    end
  end
end
