RSpec.describe 'handovers/in_progress' do
  let(:prison_code) { 'PRI' }
  let(:all_false_hash) { Hash.new { |h, k| h[k] = false } }
  let(:cases) do
    [
      [
        double(:calculated_dates1, handover_date: Date.new(2022, 1, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname1, Firstname1',
                        last_name: 'Surname1',
                        offender_no: 'X1111XX',
                        tier: 'A',
                        earliest_release: { type: 'TED', date: Date.new(2022, 1, 30) },
                        case_allocation: 'NPS',
                        allocated_com_name: 'Com One',
                        allocated_com_email: 'com1@example.org',
                        handover_progress_task_completion_data: all_false_hash,
                        handover_progress_complete?: false),
      ],
      [
        double(:calculated_dates2, handover_date: Date.new(2022, 2, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname2, Firstname2',
                        last_name: 'Surname2',
                        offender_no: 'X2222XX',
                        tier: 'B',
                        earliest_release: { type: 'HDCED', date: Date.new(2030, 1, 1) },
                        case_allocation: 'CRC',
                        allocated_com_name: 'Com Two',
                        allocated_com_email: 'x',
                        handover_progress_task_completion_data: all_false_hash,
                        handover_progress_complete?: false),
      ]
    ]
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:first_row) { page.find '.in-progress-handovers .allocated-offender:first-child' }
  let(:first_row_text) { first_row.text.strip.gsub(/\s+/, ' ') }

  before do
    stub_template 'shared/_pagination.html.erb' => ''
    assign(:paginated_handover_cases, cases)
    assign(:prison_id, prison_code)
    assign(:pom_view, true)
  end

  describe 'in the general case' do
    before do
      render
    end

    it 'shows offender details correctly' do
      expect(first_row_text).to include 'Surname1, Firstname1 X1111XX'
    end

    it 'shows COM details correctly' do
      expect(first_row_text).to include 'Com One com1@example.org'
    end

    it 'shows handover dates correctly' do
      aggregate_failures do
        expect(first_row_text).to include 'COM responsible: 12 Jan 2022'
      end
    end

    it 'shows earliest release date correctly' do
      expect(first_row_text).to include 'TED: 30 Jan 2022'
    end

    it 'shows tier information correctly' do
      expect(first_row_text).to include 'A NPS (legacy)'
    end

    it 'shows more than one case on the page' do
      expect(page).to have_css('.in-progress-handovers .allocated-offender', count: 2)
    end
  end

  describe 'when no COM is allocated and 2 days after COM responsible date' do
    it 'shows a warning' do
      allow(cases[0][1]).to receive(:allocated_com_name).and_return nil
      render
      expect(first_row_text).to include 'Unknown Allocation overdue'
    end
  end
end
