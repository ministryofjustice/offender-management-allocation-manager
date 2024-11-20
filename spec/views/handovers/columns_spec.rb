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

  specify 'the rendered table has the correct sortable column headings' do
    rendered_columns = page.all(".#{data[:table_class]} thead th")

    data[:has_sortable_columns].each_with_index do |(column_name, sortable_field), i|
      if sortable_field
        expect(rendered_columns[i]).to have_link(column_name, href: /\?sort=#{sortable_field}\+(asc|desc)/)
      else
        expect(rendered_columns[i].text).to eq(column_name)
      end
    end
  end

  specify 'the header is correct' do
    expect(page).to have_css('.govuk-heading-l,.govuk-heading-m', text: data[:heading])
  end
end

describe 'handovers/upcoming.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Upcoming handovers',
                  table_class: 'upcoming-handovers',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'POM' => 'staff_member_full_name_ordered',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }
end

describe 'handovers/in_progress.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Handovers in progress',
                  table_class: 'in-progress-handovers',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'POM' => 'staff_member_full_name_ordered',
                    'COM details' => 'allocated_com_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }
end

describe 'handovers/com_allocation_overdue.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'COM allocation overdue',
                  table_class: 'com-allocation-overdue',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'POM' => 'staff_member_full_name_ordered',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Days overdue' => 'com_allocation_days_overdue',
                    'LDU details' => nil
                  }
end

describe 'handovers/overdue_tasks.html.erb' do
  it_behaves_like 'handover cases table',
                  heading: 'Overdue tasks',
                  table_class: 'overdue-tasks-handovers',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'POM' => 'staff_member_full_name_ordered',
                    'COM details' => 'allocated_com_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }
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
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }

  it_behaves_like 'handover cases table',
                  heading: 'Handovers in progress',
                  id: 'in-progress-handovers',
                  table_class: 'in-progress-handovers',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'COM details' => 'allocated_com_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }

  it_behaves_like 'handover cases table',
                  heading: 'Overdue tasks',
                  id: 'overdue-tasks',
                  table_class: 'overdue-tasks',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'COM details' => 'allocated_com_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Handover progress' => nil
                  }

  it_behaves_like 'handover cases table',
                  heading: 'COM allocation overdue',
                  id: 'overdue-com-allocations',
                  table_class: 'overdue-com-allocation',
                  has_sortable_columns: {
                    'Prisoner details' => 'offender_last_name',
                    'COM responsible' => 'handover_date',
                    'Earliest release date' => 'earliest_release_date',
                    'Tier' => 'tier',
                    'Days overdue' => 'com_allocation_days_overdue',
                    'LDU details' => nil
                  }
end
