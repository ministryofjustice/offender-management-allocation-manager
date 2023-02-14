class Handover::EmailPreferencesForm
  include ActiveModel::Model

  FIELDS = OffenderEmailOptOut::FIELDS

  attr_accessor :staff_member_id, *FIELDS

  validates(*FIELDS, presence: true, inclusion: [true, false])

  def self.load_opt_outs(staff_member:)
    model = new
    model.staff_member_id = staff_member.staff_id
    # Load attributes from DB - remember, opt out is reversed

    FIELDS.each do |field|
      opt_out = OffenderEmailOptOut.find_by(staff_member_id: model.staff_member_id, offender_email_type: field)
      model.send("#{field}=", opt_out.nil?)
    end

    model
  end

  def update!(params)
    FIELDS.each do |field|
      value = params.fetch(field)
      send("#{field}=", value)

      if value == '1'
        OffenderEmailOptOut.find_by(staff_member_id: staff_member_id, offender_email_type: field)&.destroy
      else
        OffenderEmailOptOut.find_or_create_by!(staff_member_id: staff_member_id, offender_email_type: field)
      end
    end

    self
  end
end
