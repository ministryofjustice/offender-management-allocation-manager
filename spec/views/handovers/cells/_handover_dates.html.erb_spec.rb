RSpec.describe 'handovers/cells/_handover_dates' do
  let(:handover_case) do
    instance_double(Handover::HandoverCase,
                    handover_date: Date.new(2020, 12, 15)) # must be well in the past to trigger 'due soon' highlight
  end

  describe 'in the simplest case' do
    before do
      render 'handovers/cells/handover_dates', handover_case: handover_case, show_highlight: nil
    end

    it 'renders correct date' do
      expect(rendered_text).to eq '15 Dec 2020'
    end

    it 'has no highlights' do
      expect(page).not_to have_css '.highlight-primary'
    end
  end

  describe 'when tasks overdue' do
    before do
      assign(:handover_cases, double(overdue_tasks: [handover_case]))
      render 'handovers/cells/handover_dates', handover_case: handover_case, show_highlight: :tasks_overdue
    end

    it 'has alert highlight' do
      aggregate_failures do
        expect(partial).to have_css '.highlight-primary.highlight-alert'
        expect(partial).to have_css '.highlight-secondary.highlight-alert'
      end
    end
  end

  describe 'when due soon' do
    before do
      render 'handovers/cells/handover_dates', handover_case: handover_case, show_highlight: :due_soon
    end

    it 'has notice highlight' do
      aggregate_failures do
        expect(partial).to have_css '.highlight-primary.highlight-notice'
        expect(partial).to have_css '.highlight-secondary.highlight-notice'
      end
    end
  end
end
