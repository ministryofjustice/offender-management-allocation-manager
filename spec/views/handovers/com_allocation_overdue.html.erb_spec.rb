RSpec.describe 'handovers/com_allocation_overdue' do
  let(:prison_code) { 'PRI' }
  let(:all_false_hash) { Hash.new { |h, k| h[k] = false } }
  let(:offender) do
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
                    model: double(handover_date: Faker::Date.backward),
                    ldu_name: 'LDU Name',
                    ldu_email_address: 'ldu-email@example.org',
                   )
  end
  let(:cases) do
    [
      [double(:calculated_dates1, handover_date: Date.new(2022, 1, 12)), offender],
    ]
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:first_row) { page.find '.com-allocation-overdue .allocated-offender:first-child' }
  let(:first_row_text) { first_row.text.strip.gsub(/\s+/, ' ') }

  before do
    stub_template 'shared/_pagination.html.erb' => ''
    assign(:filtered_handover_cases, cases)
    assign(:prison_id, prison_code)
    assign(:pom_view, true)
  end

  describe 'when no LDU details' do
    it 'shows appropriate message' do
      allow(offender).to receive(:ldu_name).and_return(nil)
      allow(offender).to receive(:ldu_email_address).and_return(nil)
      render

      expect(first_row_text).to match(/we don’t have this information/i)
    end
  end

  describe 'when no LDU email' do
    it 'shows appropriate message' do
      allow(offender).to receive(:ldu_email_address).and_return(nil)
      render

      expect(first_row_text).to match(/check how to contact ldu name/i)
    end
  end

  describe 'when LDU details present' do
    it 'shows appropriate message' do
      render

      expect(first_row_text).to match(/ldu name.+ldu-email@example.org/i)
    end
  end
end
