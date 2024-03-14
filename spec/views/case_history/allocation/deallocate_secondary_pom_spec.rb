RSpec.describe "case_history/allocation/_deallocate_secondary_pom", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:history_version) do
    double(event_trigger: 'sausage and chips',
           previous_secondary_pom_name: previous_secondary_pom_name,
           previous_secondary_pom_email: previous_secondary_pom_email,
           created_at: Time.zone.now - 100,
           created_by_name: 'Mary Brown'
          )
  end

  before do
    render partial: 'case_history/allocation/deallocate_secondary_pom', locals: { deallocate_secondary_pom: history_version }
  end

  context 'with populated deallocate_secondary_pom.previous_secondary_pom_name' do
    let(:previous_secondary_pom_name) { 'Benny Bishbosh' }
    let(:previous_secondary_pom_email) { 'benny@bosh.com' }

    it 'renders previous 2ndary POM details' do
      expect(page).to have_text('Prisoner unallocated co-working POM')
      expect(page).to have_text('Benny Bishbosh')
    end
  end

  context 'with blank deallocate_secondary_pom.previous_secondary_pom_name' do
    let(:previous_secondary_pom_name) { nil }
    let(:previous_secondary_pom_email) { nil }

    it 'renders previous 2ndary POM details with no name' do
      expect(page).to have_text('Prisoner unallocated co-working POM')
    end
  end
end
