class Manage::HandoverChangesController < ApplicationController
  before_action :authenticate_user, :ensure_admin_user
  before_action { redirect_to '/' if default_prison_code.blank? }
  before_action { @prison = Prison.find_by(code: default_prison_code) }

  def historic
    @selected_date = params[:date].present? ? Date.parse(params[:date]) : Time.zone.today

    @handover_changes = PaperTrail::Version
      .select('DISTINCT ON(nomis_offender_id) nomis_offender_id, *')
      .where(item_type: CalculatedHandoverDate.to_s, event: 'update')
      .where('created_at > ? AND created_at < ?', @selected_date.beginning_of_day, @selected_date.end_of_day)
      .order('nomis_offender_id, created_at desc')
      .map { historic_handover_change(it) }
  end

  def live
    @hide_new_records = params[:hide_new_records] == 'true' || params[:hide_new_records].nil?

    @handover_changes = OffenderService
      .get_offenders_in_prison(@prison)
      .select(&:inside_omic_policy?)
      .map { live_handover_change(it) }
      .compact
      .select(&:changed?)
      .select { @hide_new_records ? it.last_calculated_at.present? : true }
  end

private

  def live_handover_change(offender)
    calculated_handover = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)
    live_handover = HandoverDateService.handover(offender)
    live_handover.last_calculated_at = Time.zone.now

    HandoverChange.new(calculated_handover, live_handover)
  rescue StandardError
    nil
  end

  def historic_handover_change(version)
    old_handover = version.reify
    new_handover = old_handover.dup
    new_handover.assign_attributes(version.changeset.transform_values(&:last))
    HandoverChange.new(old_handover, new_handover)
  end

  HandoverChange = Struct.new(:old_handover, :new_handover) do
    delegate :responsibility, :handover_date, :start_date, :reason, :last_calculated_at, :nomis_offender_id, to: :old_handover, allow_nil: true
    delegate :responsibility, :handover_date, :start_date, :reason, :last_calculated_at, :nomis_offender_id, to: :new_handover, prefix: :new

    def changed?
      responsibility != new_responsibility || reason != new_reason ||
      handover_date != new_handover_date || start_date != new_start_date
    end
  end
end
