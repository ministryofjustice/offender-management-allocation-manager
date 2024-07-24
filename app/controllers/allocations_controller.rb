# frozen_string_literal: true

class AllocationsController < PrisonsApplicationController
  before_action :ensure_spo_user, except: :history
  before_action :load_prisoner

  def show
    allocation = AllocationHistory.find_by!(nomis_offender_id: @prisoner.offender_no)
    @allocation = CaseHistory.new(allocation.get_old_versions.last, allocation, allocation.versions.last)
    @oasys_assessment = HmppsApi::AssessRisksAndNeedsApi.get_latest_oasys_date(@prisoner.offender_no)

    @pom = StaffMember.new(@prison, @allocation.primary_pom_nomis_id)
    unless @pom.has_pom_role?
      redirect_to prison_pom_non_pom_path(@prison.code, @pom.staff_id)
      return
    end

    secondary_pom_nomis_id = @allocation.secondary_pom_nomis_id
    if secondary_pom_nomis_id.present?
      coworker = StaffMember.new(@prison, secondary_pom_nomis_id)
      if coworker.has_pom_role?
        @coworker = coworker
      end
    end
    @keyworker = HmppsApi::KeyworkerApi.get_keyworker(active_prison_id, @prisoner.offender_no)
    @emails_sent_to_ldu = EmailHistory.sent_within_current_sentence(@prisoner, EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
    retrieve_latest_allocation_details
  end

  def history
    @prisoner = offender(nomis_offender_id_from_url)
    @timeline = HmppsApi::PrisonApi::MovementApi.movements_for nomis_offender_id_from_url

    allocation = AllocationHistory.find_by!(nomis_offender_id: nomis_offender_id_from_url)
    vlo_history = PaperTrail::Version
        .where(item_type: 'VictimLiaisonOfficer', nomis_offender_id: nomis_offender_id_from_url).map { |vlo_version| VloHistory.new(vlo_version) }
    complexity_history = if @prison.womens?
                           hists = HmppsApi::ComplexityApi.get_history(nomis_offender_id_from_url)
                           if hists.any?
                             [ComplexityNewHistory.new(hists.first)] +
                               hists.each_cons(2).map do |hpair|
                                 ComplexityChangeHistory.new(hpair.first, hpair.second)
                               end
                           end
                         end
    complexity_history = [] if complexity_history.nil?
    email_history = EmailHistory.where(nomis_offender_id: nomis_offender_id_from_url)
    early_allocations = Offender.includes(:early_allocations).find_by!(nomis_offender_id: nomis_offender_id_from_url).early_allocations

    ea_history = early_allocations.map { |ea|
      if ea.updated_by_firstname.present?
        [EarlyAllocationHistory.new(ea), EarlyAllocationDecision.new(ea)]
      else
        [EarlyAllocationHistory.new(ea)]
      end
    }.flatten

    @history = (AllocationService.history(allocation) + vlo_history + complexity_history + email_history + ea_history).sort_by(&:created_at)
  end

private

  def offender(nomis_offender_id)
    OffenderService.get_offender(nomis_offender_id)
  end

  def nomis_offender_id_from_url
    params.require(:prisoner_id)
  end

  def load_prisoner
    @prisoner = OffenderService.get_offender(nomis_offender_id_from_url)
  end
end
