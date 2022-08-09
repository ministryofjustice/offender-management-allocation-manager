RSpec.describe HandoverCasesList do
  let(:offender_numbers) { ('A'..'G').to_a }
  let(:offenders) do
    value = {}
    offender_numbers.each { |no| value[no] = double("offender#{no}", offender_no: no, allocated_com_name: nil) }
    value
  end
  let(:staff_member) { instance_double StaffMember, :staff_member, unreleased_allocations: offenders.values }
  let(:handover_cases_list) { described_class.new(staff_member: staff_member) }
  let(:upcoming_calculated_handover_dates) do
    [
      double(:upcoming1, nomis_offender_id: 'A'),
      double(:upcoming2, nomis_offender_id: 'C'),
    ]
  end
  let(:in_progress_calculated_handover_dates) do
    [
      double(:in_progress1, nomis_offender_id: 'D'),
      double(:in_progress2, nomis_offender_id: 'F'),
    ]
  end

  before do
    allow(CalculatedHandoverDate).to receive(:by_upcoming_handover)
                                       .with(offender_ids: offender_numbers)
                                       .and_return(double(to_a: upcoming_calculated_handover_dates))
    allow(CalculatedHandoverDate).to receive(:by_handover_in_progress)
                                       .with(offender_ids: offender_numbers)
                                       .and_return(double(to_a: in_progress_calculated_handover_dates))
  end

  describe '#upcoming' do
    it 'gets a list of handover cases whose handovers are upcoming' do
      expect(handover_cases_list.upcoming).to eq([[upcoming_calculated_handover_dates[0], offenders['A']],
                                                  [upcoming_calculated_handover_dates[1], offenders['C']]])
    end

    it 'does not include upcoming handover cases with a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(handover_cases_list.upcoming.map(&:second)).not_to include(offenders['C'])
    end
  end

  describe '#in_progress' do
    it 'gets a list of handover cases whose handovers are in progress' do
      expect(handover_cases_list.in_progress).to eq([[in_progress_calculated_handover_dates[0], offenders['D']],
                                                     [in_progress_calculated_handover_dates[1], offenders['F']]])
    end

    it 'includes upcoming handover cases that have a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(handover_cases_list.in_progress.map(&:second)).to include(offenders['C'])
    end
  end
end
