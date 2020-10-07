require 'rails_helper'

feature 'Service Notification' do
  before do
    signin_spo_user
  end

  it 'does not display service notification if none exist',
     vcr: { cassette_name: :service_notifications_none_exist } do
    allow(ServiceNotificationsService).to receive(:notifications).and_return([])

    visit root_path
    expect(page).not_to have_css('.service_banner')
  end

  context 'when there are relevant service notifications' do
    let(:messages) do
      [
        { 'id' => 'testing',
          'start_date' => 2.days.ago.strftime("%d/%m/%Y"),
          'role' => ["SPO"],
          'end_date' => 4.days.from_now.strftime("%d/%m/%Y"),
          'text' => 'An example message'
        }
      ]
    end

    before do
      allow(ServiceNotificationsService).to receive(:notifications).and_return(messages)
    end

    it 'does not display service notifications on static pages',
       vcr: { cassette_name: :service_notifications_static_pages } do
      visit "/404"

      expect(page).not_to have_css('.service_banner')
    end

    it 'displays service notifications on dynamic pages',
       vcr: { cassette_name: :service_notifications_dynamic_pages } do
      visit root_path

      expect(page).to have_css('.service_banner')
      expect(page).to have_content(messages.first['text'])
    end

    context 'when user clicks on close button', js: true do
      it 'permanently hides the notification',
         vcr: { cassette_name: :service_notifications_close_button } do
        visit root_path

        expect(page).to have_css('.service_banner')

        # close the notification
        click_on(class: 'close-service-notification')
        expect(page).not_to have_css('.service_banner')

        # go to a static page (where service notifications are not displayed)
        visit help_path

        # go back to home page
        visit root_path

        # should have no notifications displayed
        expect(page).not_to have_css('.service_banner')
      end
    end
  end
end
