RSpec.describe "allocations/show", type: :view do
  let(:prison) { build(:prison) }
  let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
  let(:offender) do
    instance_double(MpcOffender,
                    offender_no: nomis_offender_id,
                    pom_responsible?: true,
                    com_responsible?: false,
                    pom_supporting?: true,
                    responsibility_override?: false,
                    needs_a_com?: false,
                    full_name: Faker::Name.first_name,
                    last_name: Faker::Name.last_name,
                    date_of_birth: Faker::Date.backward,
                    category_label: 'X',
                    tier: 'A',
                    manual_entry?: false,
                    handover_start_date: nil,
                    handover_date: nil,
                    handover_type: 'missing',
                    tariff_date: nil,
                    parole_eligibility_date: nil,
                    target_hearing_date: nil,
                    current_parole_review: build(:parole_review, :approaching_parole),
                    previous_parole_reviews: [build(:parole_review)]
                   ).as_null_object
  end

  let(:page) { Nokogiri::HTML(rendered) }

  before do
    assign(:prison, prison)
    assign(:pom, build(:pom))
    assign(:prisoner, offender)
    assign(:allocation, create(:allocation_history, prison: build(:prison).code))
    assign(:keyworker, build(:keyworker))

    stub_template 'shared/_badges.html.erb' => ''
    stub_template 'shared/_offence_info.html.erb' => ''
    stub_template 'prisoners/_community_information.html.erb' => ''

    allow(view).to receive(:vlo_tag).and_return('')
    allow(view).to receive(:prisoner_location).and_return('')
    assign(:prisoner, offender)
  end

  describe 'responsibility' do
    before { stub_template 'shared/_vlo_information.html.erb' => '' }

    it 'allows POM responsible cases to have responsibility overridden' do
      render
      expect(page).to have_css ".responsibility_change a[href='#{new_prison_responsibility_path(prison.code, nomis_offender_id: offender.offender_no)}']"
    end

    it 'allows COM responsible overrides to be deleted' do
      allow(offender).to receive_messages(
        pom_responsible?: false,
        com_responsible?: true,
        responsibility_override?: true,
      )
      render
      expect(page).to have_css ".responsibility_change a[href='#{confirm_removal_prison_responsibility_path(prison.code, nomis_offender_id: offender.offender_no)}']"
    end
  end

  describe 'Parole section' do
    before do
      stub_const('USE_PPUD_PAROLE_DATA', true)
      stub_template 'shared/_vlo_information.html.erb' => ''
      render
    end

    it 'shows Parole section' do
      expect(page).to have_css('.govuk-table__header', text: 'Parole')
    end

    it 'shows Previous Parole section' do
      expect(page).to have_css('.govuk-table__header', text: 'Previous parole applications')
    end
  end

  describe 'VLO section' do
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
    let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_a)) }

    context 'with no VLO in nDelius' do
      let(:case_info) { build(:case_information) }

      before { render }

      it 'has a stand-alone link to create a VLO' do
        expect(page).to have_content('Add new VLO contact')
      end
    end

    context 'with active VLO in nDelius' do
      let(:case_info) { build(:case_information, :with_active_vlo) }

      context 'with no VLO in MPC' do
        before { render }

        it 'displays no VLOs' do
          expect(page).not_to have_content('Victim liaison officer name')
        end

        it 'has a message containing a link to create a VLO' do
          expect(page).to have_css('a', text: 'add it to this service')
        end

        it 'has no stand-alone link to create a VLO' do
          expect(page).not_to have_content('Add new VLO contact')
        end
      end

      context 'with VLO in MPC' do
        before do
          create(:victim_liaison_officer, offender: case_info.offender)
          render
        end

        it 'displays the VLO' do
          expect(page).to have_content('Victim liaison officer name')
        end

        it 'has no message containing a link to create a VLO' do
          expect(page).not_to have_css('a', text: 'add it to this service')
        end

        it 'has a stand-alone link to create a VLO' do
          expect(page).to have_content('Add new VLO contact')
        end
      end
    end
  end
end
