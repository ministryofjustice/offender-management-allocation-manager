describe Handover::Summary do
  subject(:handover_cases) { described_class.new(offenders.values) }

  let(:offenders) do
    ('A'..'Z').index_with do |id|
      double(
        :"offender_#{id}",
        offender_no: id,
        nomis_offender_id: id,
        allocated_com_name: nil,
        handover_progress_complete?: true
      )
    end
  end

  def calculated_handover_dates_for(*nomis_offender_ids)
    nomis_offender_ids.map do |nomis_offender_id|
      double(:"chd_for_#{nomis_offender_id}", nomis_offender_id: nomis_offender_id)
    end
  end

  def ids_of(offenders)
    offenders.map(&:nomis_offender_id)
  end

  before do
    allow(CalculatedHandoverDate).to receive(:by_upcoming_handover)
      .with(offender_ids: offenders.keys)
      .and_return(calculated_handover_dates_for 'A', 'C')

    allow(CalculatedHandoverDate).to receive(:by_handover_in_progress)
      .with(offender_ids: offenders.keys)
      .and_return(calculated_handover_dates_for 'D', 'F', 'G', 'H')

    allow(CalculatedHandoverDate).to receive(:by_com_allocation_overdue)
      .with(offender_ids: offenders.keys)
      .and_return(calculated_handover_dates_for 'J', 'K')
  end

  describe '#upcoming' do
    it 'returns cases whose handovers are upcoming' do
      expect(ids_of handover_cases.upcoming).to eq(['A', 'C'])
    end

    it 'does not include upcoming handover cases with a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(ids_of handover_cases.upcoming).not_to include('C')
    end
  end

  describe '#in_progress' do
    it 'returns cases whose handovers are in progress' do
      expect(ids_of handover_cases.in_progress).to eq(['D', 'F', 'G', 'H'])
    end

    it 'returns upcoming cases with a COM allocated' do
      allow(offenders['C']).to receive(:allocated_com_name).and_return('TEST COM NAME')

      expect(ids_of handover_cases.in_progress).to include('C')
    end
  end

  describe '#overdue_tasks' do
    it 'returns in progress cases with incomplete handover tasks' do
      allow(offenders['G']).to receive(:handover_progress_complete?).and_return(false)
      allow(offenders['H']).to receive(:handover_progress_complete?).and_return(false)

      expect(ids_of handover_cases.overdue_tasks).to eq(['G', 'H'])
    end
  end

  describe '#com_allocation_overdue' do
    it 'returns cases that are overdue COM allocation' do
      expect(ids_of handover_cases.com_allocation_overdue).to eq(['J', 'K'])
    end
  end
end
