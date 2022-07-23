RSpec.describe HandoverCasesList do
  let(:staff_member) { instance_double StaffMember, :staff_member }
  let(:cases_list) { described_class.new(staff_member) }

  # Before: Define default dependencies that do return blanks/nils/empty-collections
  #
  # No handover: determinate sentence that is <= 10 months
  # Upcoming: COM is not allocated, and today is 8 weeks before COM allocation date
  # In progress: COM allocated, and before COM responsibility date

  describe '#counts' do
    it 'has counts of handover cases in each stage' do
      expect(cases_list.counts).to eq upcoming: 4, in_progress: 3
    end
  end

  describe '#in_progress' do
    it 'gets a list of handover cases whose handovers are in progress' do
      case1 = instance_double(AllocatedOffender, :case1), instance_double(CalculatedHandoverDate, :case1)
      case2 = instance_double(AllocatedOffender, :case2), instance_double(CalculatedHandoverDate, :case2)

      expect(cases_list.upcoming).to eq [case1, case2]
    end
  end
end
