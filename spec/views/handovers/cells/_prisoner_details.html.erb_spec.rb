RSpec.describe 'handovers/cells/_prisoner_details' do
  let(:prison_id) { 'LEI' }
  let(:offender) do
    double(full_name: 'Doe, John', last_name: 'Doe', offender_no: 'A1234BC')
  end

  describe 'when rendered for a POM' do
    before do
      render 'handovers/cells/prisoner_details', prison_id: prison_id, offender: offender, pom_view: true
    end

    it 'links to the prisoner page' do
      expect(partial).to have_link('Doe, John', href: prison_prisoner_path(prison_id, 'A1234BC'))
    end

    it 'displays the offender number' do
      expect(rendered).to include('A1234BC')
    end

    it 'sets the sort value to the last name' do
      expect(partial).to have_css('[data-sort-value="Doe"]')
    end
  end

  describe 'when rendered for an SPO/HOMD' do
    before do
      render 'handovers/cells/prisoner_details', prison_id: prison_id, offender: offender, pom_view: false
    end

    it 'links to the prisoner allocation page' do
      expect(partial).to have_link('Doe, John', href: prison_prisoner_allocation_path(prison_id, prisoner_id: 'A1234BC'))
    end

    it 'displays the offender number' do
      expect(rendered).to include('A1234BC')
    end

    it 'sets the sort value to the last name' do
      expect(partial).to have_css('[data-sort-value="Doe"]')
    end
  end
end
