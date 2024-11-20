require "rails_helper"

shared_examples 'handover cases table' do |data|
  let(:page) do
    Capybara.string(rendered).then do |page|
      data[:id] ? page.find_by_id(data[:id]) : page
    end
  end

  before do
    assign(:filtered_handover_cases, [])
    render
  end

  specify 'the rendered table has the correct column headings' do
    rendered_columns = page.all(".#{data[:table_class]} thead th").map(&:text)
    expect(rendered_columns).to eq(data[:has_columns])
  end

  specify 'the header is correct' do
    expect(page).to have_css('.govuk-heading-l,.govuk-heading-m', text: data[:heading])
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

describe 'poms/_handover_tab.html.erb' do
  before do
    assign(:pom_view, true)
    assign(:upcoming_handovers, [])
    assign(:in_progress_handovers, [])
    assign(:overdue_tasks, [])
    assign(:overdue_com_allocations, [])
    assign(:summary, double.as_null_object)
  end

  it_behaves_like 'handover cases table',
                  heading: 'Upcoming handovers',
                  id: 'upcoming-handovers',
                  table_class: 'upcoming-handovers',
                  has_columns: ['Prisoner details', 'COM responsible', 'Earliest release date', 'Tier', 'Handover progress']

  it_behaves_like 'handover cases table',
                  heading: 'Handovers in progress',
                  id: 'in-progress-handovers',
                  table_class: 'in-progress-handovers',
                  has_columns: ["Prisoner details", "COM details", "COM responsible", "Earliest release date", "Tier", "Handover progress"]

  it_behaves_like 'handover cases table',
                  heading: 'Overdue tasks',
                  id: 'overdue-tasks',
                  table_class: 'overdue-tasks',
                  has_columns: ["Prisoner details", "COM details", "COM responsible", "Earliest release date", "Tier", "Handover progress"]

  it_behaves_like 'handover cases table',
                  heading: 'COM allocation overdue',
                  id: 'overdue-com-allocations',
                  table_class: 'overdue-com-allocation',
                  has_columns: ["Prisoner details", "COM responsible", "Earliest release date", "Tier", "Days overdue", "LDU details"]
end
