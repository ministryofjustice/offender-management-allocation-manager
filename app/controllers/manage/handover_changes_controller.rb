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
      .map { HandoverChangeSet.new(it.nomis_offender_id, it.changeset) }
  end

  def live
    @hide_new_records = params[:hide_new_records] == 'true' || params[:hide_new_records].nil?

    @handover_changes = OffenderService
      .get_offenders_in_prison(@prison)
      .select(&:inside_omic_policy?)
      .map { live_changeset_for(it) }
      .compact
      .select(&:changed?)
      .select { @hide_new_records ? it.last_calculated_at.present? : true }
  end

private

  def live_changeset_for(offender)
    calculated_handover = CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)
    live_handover = HandoverDateService.handover(offender)

    calculated_handover.assign_attributes(live_handover.attributes)
    calculated_handover.last_calculated_at = Time.zone.now

    HandoverChangeSet.new(offender.nomis_offender_id, calculated_handover.changes)
  rescue StandardError
    nil
  end

  HandoverChangeSet = Struct.new(:nomis_offender_id, :changeset) do
    def responsibility = changeset['responsibility']&.first
    def new_responsibility = changeset['responsibility']&.last
    def handover_date = changeset['handover_date']&.first
    def new_handover_date = changeset['handover_date']&.last
    def start_date = changeset['start_date']&.first
    def new_start_date = changeset['start_date']&.last
    def reason = changeset['reason']&.first
    def new_reason = changeset['reason']&.last
    def last_calculated_at = changeset['last_calculated_at']&.first
    def new_last_calculated_at = changeset['last_calculated_at']&.last

    def changed? = changeset.present? &&
      responsibility != new_responsibility ||
      handover_date != new_handover_date ||
      start_date != new_start_date ||
      reason != new_reason
  end
end
