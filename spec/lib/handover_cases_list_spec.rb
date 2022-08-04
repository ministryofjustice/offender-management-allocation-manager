RSpec.describe HandoverCasesList do
  let(:offender_numbers) { ('A'..'G').to_a }
  let(:allocated_offenders) do
    value = {}
    offender_numbers.each { |no| value[no] = double("offender#{no}", offender_no: no, allocated_com_name: nil) }
    value
  end
  let(:staff_member) { instance_double StaffMember, :staff_member, allocations: allocated_offenders.values }
  let(:handover_cases_list) { described_class.new(staff_member: staff_member) }

  describe '#upcoming' do
    let(:upcoming_cal_handover_dates) do
      [
        double(:upcoming1, nomis_offender_id: 'A'),
        double(:upcoming3, nomis_offender_id: 'C'),
      ]
    end
    let(:upcoming_query) { double(:upcoming_query, to_a: upcoming_cal_handover_dates) }

    before do
      allow(CalculatedHandoverDate).to receive(:by_upcoming_handover)
                                         .with(offender_ids: offender_numbers).and_return(upcoming_query)
    end

    it 'gets a list of handover cases whose handovers are upcoming' do
      expect(handover_cases_list.upcoming).to eq([[upcoming_cal_handover_dates[0], allocated_offenders['A']],
                                                  [upcoming_cal_handover_dates[1], allocated_offenders['C']]])
    end

    it 'does not include upcoming handover cases with a COM allocated' do
      allow(allocated_offenders['D']).to receive(:allocated_com_name).and_return('TEST COM NAME')
      upcoming_cal_handover_dates.push(double(:allocated_upcoming, nomis_offender_id: 'D'))

      expect(handover_cases_list.upcoming).not_to include([upcoming_cal_handover_dates.last, allocated_offenders['D']])
    end
  end
end
