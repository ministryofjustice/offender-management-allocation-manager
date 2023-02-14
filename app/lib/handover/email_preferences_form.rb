class Handover::EmailPreferencesForm
  include ActiveModel::Model

  OPT_OUT_FIELDS = OffenderEmailOptOut::OPT_OUT_FIELDS

  attr_accessor :staff_member_id, *OPT_OUT_FIELDS

  validates(*OPT_OUT_FIELDS, presence: true, inclusion: [true, false])

  def self.load(staff_member:)
    model = new
    model.staff_member_id = staff_member.staff_id
    # Load attributes from DB - remember, opt out is reversed
    model.upcoming_handover_window = true
    model.handover_date = true
    model.com_allocation_overdue = true

    model
  end

  def update!(params)
    self.upcoming_handover_window = params[:upcoming_handover_window]
    self.handover_date = params[:handover_date]
    self.com_allocation_overdue = params[:com_allocation_overdue]

    self
  end
end
