RSpec.describe "prisoners/review_case_details", type: :view do
  before do
    assign(:prison, prison)
    assign(:prisoner, offender)
    assign(:keyworker, build(:keyworker))
    assign(:alerts, [])

    stub_template 'shared/_mappa.html.erb' => ''
    stub_template 'shared/_rosh.html.erb' => ''
  end

  let(:page) { Capybara.string(rendered) }
  let(:sentence_and_offence_table) { page.find('#accordion-default-content-1 table.govuk-table') }
  let(:handover_table) { page.find('#accordion-default-content-2 table.govuk-table') }
  let(:contacts_table) { page.all('table.govuk-table').last }
  let(:vlo_row) { contacts_table.find('tr', text: 'Victim liaison officer (VLO)') }
  let(:vlo_cells) { vlo_row.all('td') }
  let(:at_a_glance_summary) { page.all('dl.govuk-summary-list').first }
  let(:case_info) { build(:case_information, :manual_entry, rosh_level: 'HIGH') }
  let(:prison) { build(:prison) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_a)) }
  let(:rosh_level_feature_enabled) { true }

  before do
    stub_rosh_level_feature(enabled: rosh_level_feature_enabled)
  end

  describe 'Sentence and offence section' do
    before { render }

    it 'renders the ordinary rows as two visible columns using colspan on the value cell' do
      rows_by_label = sentence_and_offence_table.all('tr').index_by { |row| row.all('td, th').first.text.squish }

      ['Main offence', 'Sentence start date'].each do |label|
        row = rows_by_label.fetch(label)

        expect(row).to have_css('td', count: 2)
        expect(row).to have_css('td[colspan="2"]', count: 1)
      end
    end
  end

  describe 'At a glance section' do
    before { render }

    it 'shows the rosh row' do
      row = at_a_glance_summary.find('#rosh-row')

      expect(row).to have_text('ROSH')
      expect(row).to have_text('High')
    end

    it 'shows the rosh change link when the feature flag is enabled and the case information is editable' do
      row = at_a_glance_summary.find('#rosh-row')

      expect(row).to have_link('Change', href: edit_prison_prisoner_case_information_path(prison, offender.offender_no, from: :review_case))
    end

    context 'when the rosh feature flag is disabled' do
      let(:rosh_level_feature_enabled) { false }

      it 'does not show the rosh change link' do
        row = at_a_glance_summary.find('#rosh-row')

        expect(row).not_to have_link('Change', href: edit_prison_prisoner_case_information_path(prison, offender.offender_no, from: :review_case))
      end
    end
  end

  describe 'Handover section' do
    before { render }

    it 'renders the ordinary rows as two visible columns using colspan on the value cell' do
      rows_by_label = handover_table.all('tr').index_by { |row| row.all('td, th').first.text.squish }

      ['LDU', 'LDU email', 'COM', 'COM email'].each do |label|
        row = rows_by_label.fetch(label)

        expect(row).to have_css('td', count: 2)
        expect(row).to have_css('td[colspan="2"]', count: 1)
      end
    end
  end

  describe 'VLO section' do
    context 'with no VLO in nDelius' do
      it 'has a stand-alone link to create a VLO' do
        render
        expect(vlo_cells[1]).to have_link('Add new VLO contact')
        expect(vlo_cells[2]).not_to have_link('Add new VLO contact')
      end

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(vlo_row).not_to have_css('.vlo-details')
        end

        it 'indicates no VLOs added' do
          expect(vlo_cells[1]).to have_text('No VLO details added')
        end

        it 'renders the VLO row with separate details and actions cells' do
          expect(vlo_row).to have_css('td', count: 3)
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(vlo_row).to have_css('.vlo-details')
        end

        it 'does not indicate no VLOs added' do
          expect(vlo_row).not_to have_css('td', text: 'No VLO details added')
        end

        it 'shows the management links in a separate actions cell' do
          expect(vlo_row).to have_css('td', count: 3)
          expect(vlo_cells[1]).to have_link('Add new VLO contact')
          expect(vlo_cells[2]).not_to have_link('Add new VLO contact')
          expect(vlo_cells[2]).to have_link('Change details')
          expect(vlo_cells[2]).to have_link('Remove contact')
        end
      end
    end

    context 'with active VLO in nDelius' do
      let(:case_info) { build(:case_information, :with_active_vlo) }

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(vlo_row).not_to have_css('.vlo-details')
        end

        it 'has a message containing a link to create a VLO' do
          expect(vlo_row).to have_css('td[colspan="2"] a', text: 'add it to this service')
        end

        it 'has no stand-alone link to create a VLO' do
          expect(vlo_row).not_to have_css('a', text: 'Add new VLO contact')
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(vlo_row).to have_css('.vlo-details')
        end

        it 'has no message containing a link to create a VLO' do
          expect(vlo_row).not_to have_css('a', text: 'add it to this service')
        end

        it 'has a stand-alone link to create a VLO' do
          expect(vlo_cells[1]).to have_link('Add new VLO contact')
          expect(vlo_cells[2]).not_to have_link('Add new VLO contact')
        end
      end
    end
  end
end
