RSpec.describe HandoverCasesList do
  let(:offender_numbers) { %w[A B C] }
  let(:allocated_offenders) { offender_numbers.map { |no| double("offender#{no}", offender_no: no) } }
  let(:staff_member) { instance_double StaffMember, :staff_member, allocations: allocated_offenders }
  let(:handover_cases_list) { described_class.new(staff_member: staff_member) }

  describe '#upcoming' do
    it 'gets a list of handover cases whose handovers are upcoming' do
      upcoming_dates = [double(:upcoming1, nomis_offender_id: 'A'), double(:upcoming3, nomis_offender_id: 'C')]
      upcoming_query = double(:upcoming_query, to_a: upcoming_dates)
      allow(CalculatedHandoverDate).to receive(:by_upcoming_handover)
                                         .with(offender_ids: offender_numbers).and_return(upcoming_query)

      expect(handover_cases_list.upcoming).to eq([[upcoming_dates[0], allocated_offenders[0]],
                                                  [upcoming_dates[1], allocated_offenders[2]]])
    end
  end
end
