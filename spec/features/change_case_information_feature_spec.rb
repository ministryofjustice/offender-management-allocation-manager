require 'rails_helper'

feature 'Changing case information from an allocation page' do
  let(:prison) { 'LEI' }
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:offenderNo) }

  let!(:team1) { create(:team, name: 'Team One') }
  let!(:team2) { create(:team, name: 'Team Two') }

  let!(:case_info) {
    create(:case_information,
           nomis_offender_id: offender_no,
           case_allocation: 'NPS',
           tier: 'A',
           team: team1,
           probation_service: 'Wales'
    )
  }

  let(:pom) { build(:pom) }

  before do
    # Stub auth
    signin_spo_user
    stub_auth_token
    stub_user(staff_id: 100)

    # Stub offender
    stub_offender(offender)
    stub_offenders_for_prison(prison, [offender])

    # Stub a POM for allocation
    stub_poms(prison, [pom])
    stub_pom(pom)
    create(:pom_detail, nomis_staff_id: pom.staffId)

    # Stub Keyworker API
    stub_keyworker(prison, offender_no, build(:keyworker))
  end

  context 'when on the "New allocation" page' do
    before do
      visit new_prison_allocation_path(prison, offender_no)
      expect(page).to have_content('Allocate a Prison Offender Manager')
    end

    describe 'link to change service provider' do
      it 'goes directly to the page to change service provider, and returns' do
        expect(field_value('Service provider')).to eq('National Probation Service (NPS)')
        click_change_link_for 'Service provider'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content('Select the service provider')
        choose_radio_button 'Community Rehabilitation Company (CRC)'
        click_button 'Continue'
        expect(page).to have_content('Allocate a Prison Offender Manager')
        expect(field_value('Service provider')).to eq('Community Rehabilitation Company (CRC)')
      end
    end

    describe 'link to change tiering calculation' do
      it 'goes directly to the page to change tier, and returns' do
        expect(field_value('Tiering calculation')).to eq('Tier A')
        click_change_link_for 'Tiering calculation'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Choose the prisoner's tier")
        choose_radio_button 'D'
        click_button 'Continue'
        expect(page).to have_content('Allocate a Prison Offender Manager')
        expect(field_value('Tiering calculation')).to eq('Tier D')
      end
    end

    describe 'link to change team' do
      it 'goes directly to the page to change the team', js: true do
        expect(field_value('Team')).to eq('Team One')
        click_change_link_for 'Team'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Select the prisoner's Team")
        choose_team 'Team Two'
        click_button 'Continue'
        expect(page).to have_content('Allocate a Prison Offender Manager')
        expect(field_value('Team')).to eq('Team Two')
      end
    end

    describe 'link to change community probation service' do
      it "edits probation service, then edits other probation fields, then returns" do
        expect(field_value('Community probation service')).to eq('Wales')
        click_change_link_for 'Community probation service'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Was the prisoner's last known address in Northern Ireland, Scotland or Wales?")
        choose_radio_button 'No'
        click_button 'Continue'
        expect(page).to have_content('Select the service provider')
        expect(page).to have_content("Choose the prisoner's tier")
        expect(page).to have_content("Select the prisoner's Team")
        click_button 'Continue'
        expect(page).to have_content('Allocate a Prison Offender Manager')
        expect(field_value('Community probation service')).to eq('England')
      end
    end
  end

  context 'when viewing an existing allocation', versioning: true do
    before do
      # Create an allocation
      create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staffId)

      visit prison_allocation_path(prison, offender_no)
      expect(page).to have_content('Allocation information')
    end

    describe 'link to change service provider' do
      it 'goes directly to the page to change service provider, and returns' do
        expect(field_value('Service provider')).to eq('National Probation Service (NPS)')
        click_change_link_for 'Service provider'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content('Select the service provider')
        choose_radio_button 'Community Rehabilitation Company (CRC)'
        click_button 'Continue'
        expect(page).to have_content('Allocation information')
        expect(field_value('Service provider')).to eq('Community Rehabilitation Company (CRC)')
      end
    end

    describe 'link to change tiering calculation' do
      it 'goes directly to the page to change tier, and returns' do
        expect(field_value('Tiering calculation')).to eq('Tier A')
        click_change_link_for 'Tiering calculation'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Choose the prisoner's tier")
        choose_radio_button 'D'
        click_button 'Continue'
        expect(page).to have_content('Allocation information')
        expect(field_value('Tiering calculation')).to eq('Tier D')
      end
    end

    describe 'link to change team' do
      it 'goes directly to the page to change the team', js: true do
        expect(field_value('Team')).to eq('Team One')
        click_change_link_for 'Team'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Select the prisoner's Team")
        choose_team 'Team Two'
        click_button 'Continue'
        expect(page).to have_content('Allocation information')
        expect(field_value('Team')).to eq('Team Two')
      end
    end

    describe 'link to change community probation service' do
      it "edits probation service, then edits other probation fields, then returns" do
        expect(field_value('Community probation service')).to eq('Wales')
        click_change_link_for 'Community probation service'
        expect(page).to have_content('Edit case information')
        expect(page).to have_content("Was the prisoner's last known address in Northern Ireland, Scotland or Wales?")
        choose_radio_button 'No'
        click_button 'Continue'
        expect(page).to have_content('Select the service provider')
        expect(page).to have_content("Choose the prisoner's tier")
        expect(page).to have_content("Select the prisoner's Team")
        click_button 'Continue'
        expect(page).to have_content('Allocation information')
        expect(field_value('Community probation service')).to eq('England')
      end
    end
  end

private

  def field_td(name)
    page.find('td:nth-child(1)', text: name).sibling('td')
  end

  def field_value(name)
    value = field_td(name).text

    # Ignore 'Change' link text, if present
    if value.ends_with?('Change')
      length = value.length - 'Change'.length
      value = value[0, length]
    end

    value.strip
  end

  def click_change_link_for(field_name)
    field_td(field_name).find('a', text: 'Change').click
  end

  def choose_team(team_name)
    team_autocomplete = find('#team_autocomplete')
    team_autocomplete.send_keys(team_name)
    team_autocomplete.click
  end
end
