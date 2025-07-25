# frozen_string_literal: true

module FeaturesHelper
  def signin_spo_user(prisons = ['LEI'])
    mock_sso_response('MOIC_POM', [SsoIdentity::SPO_ROLE], prisons)
  end

  def stub_signin_spo(pom, prisons = ['LEI'])
    signin_spo_user(prisons)
    stub_spo_user(pom)
  end

  def stub_spo_user(pom)
    stub_user('MOIC_POM', pom.staff_id)
  end

  def stub_pom_user(pom) = stub_spo_user(pom)

  def signin_spo_pom_user(prisons = %w[LEI RSI], name = 'MOIC_POM')
    mock_sso_response(name, [SsoIdentity::SPO_ROLE, SsoIdentity::POM_ROLE], prisons)
  end

  def signin_global_admin_user
    mock_sso_response('MOIC_POM', [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE], PrisonService.prison_codes)
  end

  def signin_pom_user(prisons = %w[LEI RSI], staff_id = 485_926)
    mock_sso_response('MOIC_POM', [SsoIdentity::POM_ROLE], prisons, staff_id)
  end

  def mock_sso_response(username, roles, prisons, staff_id = 485_926)
    hmpps_sso_response = {
      'info' => double('user_info', username:, staff_id:, active_caseload: prisons.first, caseloads: prisons, roles: roles),
      'credentials' => double('credentials', expires_at: Time.zone.local(2030, 1, 1).to_i,
                                             authorities: roles,
                                             token: 'access-token'),
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end

  def stub_dps_header_footer
    allow_any_instance_of(SsoIdentity).to receive(:token).and_return('fake-user-access-token')
    allow(HmppsApi::DpsFrontendComponentsApi).to receive_messages(
      header: { 'html' => '<header>', 'css' => [], 'javascript' => [] },
      footer: { 'html' => '<footer>', 'css' => [], 'javascript' => [] },
    )
  end

  def stub_active_caseload_check
    allow_any_instance_of(PrisonsApplicationController).to receive(:check_active_caseload)
  end

  def wait_for(maximum_wait_in_seconds = 10, &block)
    Selenium::WebDriver::Wait.new(timeout: maximum_wait_in_seconds).until(&block)
  end

  def execute_in_new_tab
    current_tab = page.current_window
    new_tab = page.open_new_window

    switch_to_window(new_tab)

    yield

    switch_to_window(current_tab)

    new_tab.close
  end

  # Helpers for key/value tables
  # (e.g. those used on prisoner profile pages)
  #
  # For example, with a table like this:
  #   | Offender number | A1234BC    |
  #   | Tier            | B [Change] |
  #
  # You can update the tier using:
  #   td_for_row('Tier').click_link('Change')
  # Or expect it to have a link using:
  #   expect(td_for_row('Tier')).to have_link('Change')
  #
  # You can get the offender number using:
  #   value_for_row('Offender number')
  # Or expect a value using:
  #   expect(value_for_row('Offender number')).to eq('A1234BC')
  def td_for_row(label)
    page.find('td', text: label).sibling('td')
  end

  def value_for_row(row_label)
    td_for_row(row_label).text
  end

  # Get the <tr> containing the specified text
  # Useful when used with "within" to scope subsequent actions:
  #   within row_containing 'Name of a POM' do
  #     click_link 'Allocate'
  #   end
  def row_containing(text)
    page.find('tr', text: text)
  end

  def current_page_number
    page.find('.pagination .current.page', match: :first).text.to_i
  end

  def reload_page
    visit current_path
  end
end
