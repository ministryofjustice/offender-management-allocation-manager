RSpec.describe "prisoners/review_case_details", type: :view do
  before do
    assign(:prison, prison)
    assign(:prisoner, offender)
    assign(:keyworker, build(:keyworker))
    assign(:alerts, [])
    assign(:mappa, { status: :not_found, short_description: nil, start_date: nil })
    assign(:rosh, { status: :unable })

    stub_template 'shared/_mappa.html.erb' => ''
  end

  let(:page) { Nokogiri::HTML(rendered) }
  let(:case_info) { build(:case_information) }
  let(:prison) { build(:prison) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_a)) }

  describe 'VLO section' do
    context 'with no VLO in nDelius' do
      it 'has a stand-alone link to create a VLO' do
        render
        expect(page).to have_css('td.govuk-\!-width-one-third a', text: 'Add new VLO contact')
      end

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(page).not_to have_css('td.govuk-\!-width-one-third .vlo-details')
        end

        it 'indicates no VLOs added' do
          expect(page).to have_css('td.govuk-\!-width-one-third', text: 'No VLO details added')
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(page).to have_css('td.govuk-\!-width-one-third .vlo-details')
        end

        it 'does not indicate no VLOs added' do
          expect(page).not_to have_css('td.govuk-\!-width-one-third', text: 'No VLO details added')
        end
      end
    end

    context 'with active VLO in nDelius' do
      let(:case_info) { build(:case_information, :with_active_vlo) }

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(page).not_to have_css('td.govuk-\!-width-one-third .vlo-details')
        end

        it 'has a message containing a link to create a VLO' do
          expect(page).to have_css('td.govuk-\!-width-two-thirds a', text: 'add it to this service')
        end

        it 'has no stand-alone link to create a VLO' do
          expect(page).not_to have_css('td.govuk-\!-width-one-third a', text: 'Add new VLO contact')
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(page).to have_css('td.govuk-\!-width-one-third .vlo-details')
        end

        it 'has no message containing a link to create a VLO' do
          expect(page).not_to have_css('td.govuk-\!-width-two-thirds a', text: 'add it to this service')
        end

        it 'has a stand-alone link to create a VLO' do
          expect(page).to have_css('td.govuk-\!-width-one-third a', text: 'Add new VLO contact')
        end
      end
    end
  end
end
