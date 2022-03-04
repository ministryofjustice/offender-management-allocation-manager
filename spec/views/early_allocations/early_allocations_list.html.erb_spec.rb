require 'rails_helper'

RSpec.describe "early_allocations/early_allocations_list", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:offender) { build(:hmpps_api_offender) }

  before do
    render partial: 'early_allocations/early_allocations_list', locals: {
      early_allocations: early_allocations,
      prison_id: offender.prison_id,
      prisoner_id: offender.offender_no
    }
  end

  context 'with Early Allocation assessments' do
    let(:early_allocations) do
      # Create 5 Early Allocation records with different creation dates
      [
        create(:early_allocation, created_at: 1.year.ago),
        create(:early_allocation, created_at: 6.months.ago),
        create(:early_allocation, created_at: 1.month.ago),
        create(:early_allocation, created_at: 1.week.ago),
        create(:early_allocation, created_at: 1.day.ago)
      ]
    end

    it 'renders a table with one row for each assessment' do
      rows = page.css('table > tbody > tr')
      expect(rows.length).to eq(5)
    end

    it 'has column headings: Assessment date, Outcome, POM name, Action' do
      headings = page.css('thead th').map(&:text)
      expect(headings).to eq(['Assessment date', 'Outcome', 'POM name', 'Action'])
    end

    describe 'column values' do
      let(:rendered_values) do
        # An array of string cell values, one for each row for the table, for column specified by column_index
        page.css("tr > td:nth-child(#{column_index})").map(&:text).map(&:strip)
      end

      describe 'Assessment date' do
        let(:column_index) { 1 }

        it 'shows the date the record was created' do
          created_dates = early_allocations.map { |record| record.created_at.to_date.to_s(:rfc822) }
          expect(rendered_values).to eq(created_dates)
        end
      end

      describe 'Outcome' do
        let(:column_index) { 2 }

        context 'when eligible' do
          let(:early_allocations) { [create(:early_allocation)] }

          it 'shows "Eligible"' do
            message = "Eligible - the community probation team will take responsibility for this case early"
            expect(rendered_values.first).to eq(message)
          end
        end

        context 'when discretionary' do
          let(:early_allocations) { [create(:early_allocation, :discretionary)] }

          it 'shows "Discretionary"' do
            message = "Discretionary - the community probation team will make a decision"
            expect(rendered_values.first).to eq(message)
          end
        end

        context 'when ineligible' do
          let(:early_allocations) { [create(:early_allocation, :ineligible)] }

          it 'shows "Not eligible"' do
            message = "Not eligible"
            expect(rendered_values.first).to eq(message)
          end
        end
      end

      describe 'POM name' do
        let(:column_index) { 3 }

        it 'shows the name of the POM who created the record' do
          pom_names = early_allocations.map do |record|
            "#{record.created_by_lastname}, #{record.created_by_firstname}"
          end
          expect(rendered_values).to eq(pom_names)
        end
      end

      describe 'Action' do
        let(:column_index) { 4 }

        let(:links) { page.css("tr > td:nth-child(#{column_index}) > a") }

        it 'renders a "View" link which goes to the #show action' do
          early_allocations.each_with_index do |early_allocation, index|
            link = links[index]
            view_assessment_path = prison_prisoner_early_allocation_path(
              offender.prison_id, offender.offender_no, early_allocation.id
            )
            expect(link.text).to eq('View')
            expect(link.attribute('href').value).to eq(view_assessment_path)
          end
        end
      end
    end
  end

  context 'when there are no Early Allocation assessments' do
    let(:early_allocations) { [] }

    it 'does not render a table' do
      expect(page.css('table').present?).to be(false)
    end

    it 'renders a "no assessments" message' do
      expect(page.text.strip).to eq('This case has no saved assessments.')
    end
  end
end
