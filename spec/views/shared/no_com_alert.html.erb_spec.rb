require 'rails_helper'

RSpec.describe "shared/no_com_alert", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:offender) do
    build(:offender, :determinate, latestLocationId: 'LEI', offenderNo: 'G8060UF',
          sentence: build(:sentence_detail,
                          sentenceStartDate: Time.zone.today - 11.months,
                          conditionalReleaseDate: Time.zone.today + 8.months,
                          automaticReleaseDate: Time.zone.today + 8.months,
                          releaseDate: Time.zone.today + 8.months,
                          tariffDate: nil))
  end

  before do
    allow(OffenderService).to receive(:get_offender).and_return(offender)
  end

  context 'when offender has an LDU without an email address' do
    let(:case_info) do
      create(:case_information, nomis_offender_id: offender.offender_no,
             team: build(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil)))
    end

    before do
      offender.load_case_information(case_info)
      assign(:prisoner, OffenderPresenter.new(offender))
      render partial: 'shared/no_com_alert'
    end

    it 'displays message with the LDU name' do
      expect(page.css('#com_warning'))
        .to have_link(I18n.t('views.handover_alert.no_com', date: offender.handover_start_date.strftime('%d/%m/%Y')),
                      href: "#com-error")

      expect(page.css('#ldu_warning'))
        .to have_link(I18n.t('views.handover_alert.no_email', name: offender.ldu_name), href: "#com-error")
    end
  end

  context 'when offender does not have an LDU' do
    let(:case_info) do
      create(:case_information, nomis_offender_id: offender.offender_no, team: nil)
    end

    before do
      offender.load_case_information(case_info)
      assign(:prisoner, OffenderPresenter.new(offender))
      render partial: 'shared/no_com_alert'
    end

    it 'displays message without an LDU name' do
      expect(page.css('#com_warning'))
        .to have_link(I18n.t('views.handover_alert.no_com', date: offender.handover_start_date.strftime('%d/%m/%Y')),
                      href: "#com-error")

      expect(page.css('#ldu_warning'))
        .to have_link(I18n.t('views.handover_alert.no_ldu'), href: "#com-error")
    end
  end
end
