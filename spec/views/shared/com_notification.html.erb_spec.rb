require 'rails_helper'

RSpec.describe "shared/com_notification", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prescod_id) { PrisonService::PRESCOED_CODE }
  let(:offender) do
    build(:offender, :indeterminate, latestLocationId: prescod_id, offenderNo: 'G4251GW',
          sentence: build(:sentence_detail,
                          sentenceStartDate: Time.zone.today - 11.months,
                          releaseDate: Time.zone.today + 5.years,
                          tariffDate: Time.zone.today + 3.years))
  end

  before do
    allow(OffenderService).to receive(:get_offender).and_return(offender)
  end

  context 'when an indeterminate Welsh offender moved from closed prison to Prescoed open prison', vcr: { cassette_name: :com_notification_present } do
    let(:case_info) do
      create(:case_information, :welsh, nomis_offender_id: offender.offender_no, case_allocation: 'NPS')
    end

    let(:email_history) do
      create(:email_history, :open_prison_community_allocation, prison: prescod_id, nomis_offender_id: offender.offender_no, name: 'LDU Number 1')
    end

    before do
      offender.load_case_information(case_info)
      assign(:prisoner, offender)
      render partial: 'shared/com_notification', locals: { email: email_history }
    end

    it 'displays a notification that an email was sent to the LDU' do
      expect(page.css('#error-summary-title')).to have_content(I18n.t('views.com_notification.title'))

      expect(page.css('#com_warning'))
      .to have_link(I18n.t('views.com_notification.com_needed'), href: "#com-error")

      expect(page.css('#ldu_warning'))
      .to have_link(I18n.t('views.com_notification.ldu_contacted', date: format_date(email_history.created_at)), href: "#com-error")
    end
  end
end
