describe MpcOffender do
  let(:case_information) { instance_double CaseInformation, :case_information }
  let(:prison) { instance_double Prison, :prison }
  let(:db_offender) { instance_double Offender, :offender, case_information: case_information }
  let(:prison_record) { instance_double HmppsApi::Offender, :prison_record }
  let(:mpc_offender_handover_soon) { build_mpc_offender(today - 1.day) }

  def build_mpc_offender(handover_start_date = Time.zone.now.to_date)
    value = described_class.new(prison: prison,
                                offender: db_offender,
                                prison_record: prison_record)
    allow(value).to receive(:handover_start_date).and_return(handover_start_date)
    value
  end

  describe '#in_upcoming_handover_window?' do
    let(:today) { Date.new(2022, 12, 31) }

    it 'is true if offender is in 8-week handover window' do
      expect(mpc_offender_handover_soon.in_upcoming_handover_window?(today)).to eq true
    end

    it 'is false if offender is 8-week not in handover window' do
      mpc_offender = build_mpc_offender(today - 8.weeks - 1.day)

      expect(mpc_offender.in_upcoming_handover_window?(today)).to eq false
    end

    it 'is false if probation record is blank' do
      allow(db_offender).to receive(:case_information).and_return nil

      expect(mpc_offender_handover_soon.in_upcoming_handover_window?(today)).to eq false
    end

    it 'is false if handover start date is nil' do
      mpc_offender = build_mpc_offender(nil)

      expect(mpc_offender.in_upcoming_handover_window?(today)).to eq false
    end
  end
end
