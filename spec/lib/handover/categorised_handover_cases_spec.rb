RSpec.describe Handover::CategorisedHandoverCases do
  subject(:handover_cases) { described_class.new(offenders.values) }

  let(:offender_numbers) { ('A'..'Z').to_a }
  let(:offenders) do
    value = {}
    offender_numbers.each do |no|
      value[no] = sneaky_instance_double(AllocatedOffender,
                                         "offender#{no}",
                                         offender_no: no,
                                         allocated_com_name: nil,
                                         handover_progress_complete?: true)
    end
    value
  end
  let(:upcoming_calculated_handover_dates) do
    [
      sneaky_instance_double(CalculatedHandoverDate, :upcoming1, nomis_offender_id: 'A'),
      sneaky_instance_double(CalculatedHandoverDate, :upcoming2, nomis_offender_id: 'C'),
    ]
  end
  let(:in_progress_calculated_handover_dates) do
    [
      sneaky_instance_double(CalculatedHandoverDate, :in_progress1, nomis_offender_id: 'D'),
      sneaky_instance_double(CalculatedHandoverDate, :in_progress2, nomis_offender_id: 'F'),
    ]
  end
  let(:overdue_tasks_calculated_handover_dates) do
    [
      sneaky_instance_double(CalculatedHandoverDate, :overdue_tasks1, nomis_offender_id: 'G'),
      sneaky_instance_double(CalculatedHandoverDate, :overdue_tasks2, nomis_offender_id: 'H'),
    ]
  end
  let(:com_allocation_overdue_calculated_handover_dates) do
    [
      sneaky_instance_double(CalculatedHandoverDate, :com_allocation_overdue1, nomis_offender_id: 'J'),
      sneaky_instance_double(CalculatedHandoverDate, :com_allocation_overdue2, nomis_offender_id: 'K'),
    ]
  end

  before do
    allow(CalculatedHandoverDate).to receive(:by_upcoming_handover)
                                       .with(offender_ids: offender_numbers)
                                       .and_return(double(to_a: upcoming_calculated_handover_dates))
    allow(CalculatedHandoverDate).to(
      receive(:by_handover_in_progress)
        .with(offender_ids: offender_numbers)
        .and_return(double(to_a: in_progress_calculated_handover_dates + overdue_tasks_calculated_handover_dates))
    )
    allow(CalculatedHandoverDate).to receive(:by_com_allocation_overdue)
                                       .with(offender_ids: offender_numbers)
                                       .and_return(double(to_a: com_allocation_overdue_calculated_handover_dates))

    allow(offenders['G']).to receive(:handover_progress_complete?).and_return(false)
    allow(offenders['H']).to receive(:handover_progress_complete?).and_return(false)
  end

  describe '#upcoming' do
    it 'gets a list of handover cases whose handovers are upcoming' do
      expect(handover_cases.upcoming).to eq([
        Handover::HandoverCase.new(offenders['A'], upcoming_calculated_handover_dates[0]),
        Handover::HandoverCase.new(offenders['C'], upcoming_calculated_handover_dates[1])
      ])
    end

    it 'does not include upcoming handover cases with a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(handover_cases.upcoming.map(&:offender)).not_to include(offenders['C'])
    end
  end

  describe '#in_progress' do
    it 'gets a list of handover cases whose handovers are in progress' do
      expect(handover_cases.in_progress).to eq([
        Handover::HandoverCase.new(offenders['D'], in_progress_calculated_handover_dates[0]),
        Handover::HandoverCase.new(offenders['F'], in_progress_calculated_handover_dates[1]),
        Handover::HandoverCase.new(offenders['G'], overdue_tasks_calculated_handover_dates[0]),
        Handover::HandoverCase.new(offenders['H'], overdue_tasks_calculated_handover_dates[1]),
      ])
    end

    it 'includes upcoming handover cases that have a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(handover_cases.in_progress.map(&:offender)).to include(offenders['C'])
    end
  end

  describe '#overdue_tasks' do
    it 'gets a list of handover cases past handover and with tasks overdue' do
      expect(handover_cases.overdue_tasks).to eq([
        Handover::HandoverCase.new(offenders['G'], overdue_tasks_calculated_handover_dates[0]),
        Handover::HandoverCase.new(offenders['H'], overdue_tasks_calculated_handover_dates[1]),
      ])
    end

    it 'includes upcoming handover cases that have a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(handover_cases.in_progress.map(&:offender)).to include(offenders['C'])
    end
  end

  describe '#com_allocation_overdue' do
    it 'gets a list of handover cases that are COM allocation overdue' do
      expect(handover_cases.com_allocation_overdue).to eq([
        Handover::HandoverCase.new(offenders['J'], com_allocation_overdue_calculated_handover_dates[0]),
        Handover::HandoverCase.new(offenders['K'], com_allocation_overdue_calculated_handover_dates[1])
      ])
    end
  end
end
