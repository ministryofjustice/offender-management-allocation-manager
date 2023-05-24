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
                    responsibility_handover_date: nil).as_null_object
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
    stub_template 'shared/_vlo_information.html.erb' => ''

    allow(view).to receive(:vlo_tag).and_return('')
    allow(view).to receive(:prisoner_location).and_return('')
    assign(:prisoner, offender)
  end

  describe 'responsibility' do
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
end
