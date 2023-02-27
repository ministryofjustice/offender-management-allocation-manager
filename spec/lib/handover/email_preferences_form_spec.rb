RSpec.describe Handover::EmailPreferencesForm do
  let(:staff_member_id) { '123456' }
  let(:staff_member) { instance_double StaffMember, :staff_member, staff_id: staff_member_id }

  it "loads opt outs from database and stores them as opt-ins" do
    FactoryBot.create :offender_email_opt_out,
                      staff_member_id: staff_member_id,
                      offender_email_type: :upcoming_handover_window
    FactoryBot.create :offender_email_opt_out,
                      staff_member_id: staff_member_id,
                      offender_email_type: :com_allocation_overdue

    model = described_class.load_opt_outs(staff_member: staff_member)

    expect([model.upcoming_handover_window, model.handover_date, model.com_allocation_overdue])
      .to eq [false, true, false]
  end

  describe "when persisting" do
    subject(:model) { described_class.load_opt_outs(staff_member: staff_member) }

    let!(:existing_opt_out_record) do # forcibly create
      FactoryBot.create :offender_email_opt_out,
                        staff_member_id: staff_member_id,
                        offender_email_type: :upcoming_handover_window
    end

    it "creates and keeps opt-out record in DB when opt-in is '1'" do
      model.update!(upcoming_handover_window: nil,
                    handover_date: nil,
                    com_allocation_overdue: nil)
      expect(OffenderEmailOptOut.where(staff_member_id: staff_member_id).pluck(:offender_email_type))
        .to match_array described_class::FIELDS.map(&:to_s)
    end

    it "deletes opt-out record in DB when opt-in is nil" do
      model.update!(upcoming_handover_window: '1',
                    handover_date: '1',
                    com_allocation_overdue: '1')
      expect(OffenderEmailOptOut.count).to eq 0
    end
  end
end
