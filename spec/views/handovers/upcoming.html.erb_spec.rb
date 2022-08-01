RSpec.describe 'handovers/upcoming' do
  let(:prison_code) { 'PRI' }
  let(:upcoming_handover_cases) do
    [
      [
        double(:handover_date1, com_responsibility_date: Date.new(2022, 1, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname1, Firstname1',
                        last_name: 'Surname1',
                        offender_no: 'X1111XX',
                        tier: 'A',
                        release_date: Date.new(2022, 1, 30),
                        case_allocation: 'HDCED')
      ],
      [
        double(:handover_date2, com_responsibility_date: Date.new(2022, 2, 12)),
        instance_double(AllocatedOffender,
                        full_name: 'Surname2, Firstname2',
                        last_name: 'Surname2',
                        offender_no: 'X2222XX',
                        tier: 'B',
                        release_date: Date.new(2030, 1, 1),
                        case_allocation: 'CRC')
      ]
    ]
  end

  let(:page) { Capybara::Node::Simple.new(rendered) }
  let(:first_row) { page.find '.upcoming-handovers .allocated-offender:first-child' }

  before do
    assign(:handover_cases, double(:handover_cases, upcoming: upcoming_handover_cases))
    assign(:prison_id, prison_code)
    render
  end

  it 'shows offender details correctly' do
    prisoner_details = first_row.find('td.prisoner-details')
    link = prisoner_details.find('a')
    aggregate_failures do
      expect(link.text.strip).to eq 'Surname1, Firstname1'
      expect(link['data-sort-value']).to eq 'Surname1'
      expect(link['href']).to eq prison_prisoner_path(prison_id: prison_code, id: 'X1111XX')
      expect(prisoner_details.find('.offender-no').text.strip).to eq 'X1111XX'
    end
  end

  it 'shows COM responsible date correctly' do
    com_responsible = first_row.find('td.com-responsible')
    aggregate_failures do
      expect(com_responsible.text.strip.gsub(/\s+/, ' ')).to eq 'COM responsible: 12 Jan 2022'
      expect(com_responsible['data-sort-value']).to eq '2022-01-12'
    end
  end

  it 'shows earliest release date correctly' do
    release_date = first_row.find('td.earliest-release-date')
    aggregate_failures do
      expect(release_date.text.strip.gsub(/\s+/, ' ')).to eq 'TODO: 30 Jan 2022'
      expect(release_date['data-sort-value']).to eq '2022-01-30'
    end
  end

  it 'shows tier information correctly' do
    tier_info = first_row.find('td.tier')
    aggregate_failures do
      expect(tier_info.text.strip.gsub(/\s+/, ' ')).to eq 'A HDCED (legacy)'
      expect(tier_info['data-sort-value']).to eq 'HDCED'
    end
  end

  it 'shows more than one case on the page' do
    expect(page).to have_css('.upcoming-handovers .allocated-offender', count: 2)
  end
end
