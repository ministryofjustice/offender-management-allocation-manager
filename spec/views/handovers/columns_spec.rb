require "rails_helper"

shared_examples 'handover cases table' do |data|
  let(:page) { Capybara.string(rendered) }

  before do
    assign(:filtered_handover_cases, [])
    render
  end

  specify 'the rendered table has the correct column headings' do
    rendered_columns = page.all(".#{data[:table_class]} thead th").map(&:text)
    expect(rendered_columns).to eq(data[:has_columns])
  end

  specify 'the header is correct' do
    expect(page).to have_css('.govuk-heading-l', text: data[:heading])
  end
end

describe 'handovers/upcoming.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Upcoming handovers',
                  table_class: 'upcoming-handovers',
                  has_columns: ['Prisoner details', 'POM', 'COM responsible', 'Earliest release date', 'Tier', 'Handover progress']
end

describe 'handovers/in_progress.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Handovers in progress',
                  table_class: 'in-progress-handovers',
                  has_columns: ["Prisoner details", "POM", "COM details", "COM responsible", "Earliest release date", "Tier", "Handover progress"]
end

describe 'handovers/com_allocation_overdue.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'COM allocation overdue',
                  table_class: 'com-allocation-overdue',
                  has_columns: ["Prisoner details", "POM", "COM responsible", "Earliest release date", "Tier", "Days overdue", "LDU details"]
end

describe 'handovers/overdue_tasks.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Overdue tasks',
                  table_class: 'overdue-tasks-handovers',
                  has_columns: ["Prisoner details", "POM", "COM details", "COM responsible", "Earliest release date", "Tier", "Handover progress"]
end
