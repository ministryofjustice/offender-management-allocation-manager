RSpec.describe 'handovers/upcoming' do
  let(:prison_code) { 'PRI' }
  let(:upcoming_handover_cases) do
    [
      [
        double(:handover_date1, com_allocated_date: Date.new(2022, 1, 5),
                                com_responsible_date: Date.new(2022, 1, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname1, Firstname1',
                        last_name: 'Surname1',
                        offender_no: 'X1111XX',
                        tier: 'A',
                        earliest_release: { type: 'TED', date: Date.new(2022, 1, 30) },
                        case_allocation: 'NPS')
      ],
      [
        double(:handover_date2, com_allocated_date: Date.new(2022, 2, 5),
                                com_responsible_date: Date.new(2022, 2, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname2, Firstname2',
                        last_name: 'Surname2',
                        offender_no: 'X2222XX',
                        tier: 'B',
                        earliest_release: { type: 'HDCED', date: Date.new(2030, 1, 1) },
                        case_allocation: 'CRC')
      ]
    ]
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:first_row) { page.find '.upcoming-handovers .allocated-offender:first-child' }
  let(:first_row_text) { first_row.text.strip.gsub(/\s+/, ' ') }

  before do
    assign(:handover_cases, double(:handover_cases, upcoming: upcoming_handover_cases))
    assign(:prison_id, prison_code)
  end

  describe 'in the general case' do
    before do
      render
    end

    it 'shows offender details correctly' do
      expect(first_row_text).to include 'Surname1, Firstname1 X1111XX'
    end

    it 'shows handover dates correctly' do
      aggregate_failures do
        expect(first_row_text).to include 'COM allocated: 05 Jan 2022 COM responsible: 12 Jan 2022'
      end
    end

    it 'shows earliest release date correctly' do
      expect(first_row_text).to include 'TED: 30 Jan 2022'
    end

    it 'shows tier information correctly' do
      expect(first_row_text).to include 'A NPS (legacy)'
    end

    it 'shows more than one case on the page' do
      expect(page).to have_css('.upcoming-handovers .allocated-offender', count: 2)
    end
  end

  describe 'when com responsible date is the same as the com allocated date' do
    it 'only shows com responsible date' do
      allow(upcoming_handover_cases[0][0]).to receive(:com_allocated_date).and_return(Date.new(2022, 1, 12))
      render
      aggregate_failures do
        expect(first_row_text).to include 'COM responsible: 12 Jan 2022'
        expect(first_row_text).not_to include 'COM allocated: 12 Jan 2022'
      end
    end
  end
end
