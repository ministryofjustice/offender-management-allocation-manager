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
      Summary.new allocated: summary.fetch(:allocated, []),
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

    def enrich_offenders(offender_list)
      nomis_ids = offender_list.map(&:offender_no)
      offenders = Offender.
        includes(case_information: [:responsibility, :early_allocations, :local_delivery_unit]).
        where(nomis_offender_id: nomis_ids)

      if offenders.count != nomis_ids.count
        # Create Offender records for (presumably new) prisoners who don't have one yet
        nomis_ids.reject { |nomis_id| offenders.detect { |offender| offender.nomis_offender_id == nomis_id } }.each do |new_id|
          new_offender = Offender.find_or_create_by! nomis_offender_id: new_id
          offenders = offenders + [new_offender]
        end
      end

      mapped_tiers = offenders.
        map(&:case_information).
        compact.
        index_by(&:nomis_offender_id)

      offender_list.each { |offender|
        case_info_record = mapped_tiers[offender.offender_no]
        offender.load_case_information(case_info_record)
      }
      HmppsApi::PrisonApi::OffenderApi.add_arrival_dates(offender_list)
    end
  end
end
