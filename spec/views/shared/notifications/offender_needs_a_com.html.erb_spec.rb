require 'rails_helper'

RSpec.describe "shared/notifications/offender_needs_a_com", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:title) { page.css('#com-error-summary-title').text.strip }
  let(:com_warning) { page.css('#com_warning') }
  let(:ldu_warning) { page.css('#ldu_warning') }

  let(:case_info) { build(:case_information, :nps, local_delivery_unit: ldu, manual_entry: ldu.nil?, team: nil) }
  let(:ldu) { build(:local_delivery_unit) }
  let(:email_history) { [] }

  let(:offender) {
    build(:offender, :determinate, sentence: build(:sentence_detail, :inside_handover_window)).tap { |o|
      o.load_case_information(case_info)
    }
  }

  before do
    render partial: 'shared/notifications/offender_needs_a_com',
           locals: { offender: offender, email_history: email_history }
  end

  context 'when an email has been sent to the LDU' do
    let(:date_sent) { Time.zone.today }
    let(:email_history) { [create(:email_history, :open_prison_community_allocation, case_information: case_info, created_at: date_sent)] }

    it 'says "You may need to contact the community probation office"' do
      expect(title).to eq(I18n.t('views.notifications.offender_needs_a_com.maybe_contact_ldu'))
    end

    it 'says a supporting COM is needed' do
      text = I18n.t('views.notifications.offender_needs_a_com.com_needed')
      href = '#com-name'
      expect(com_warning).to have_link(text, href: href)
    end

    it 'says when the LDU was emailed' do
      text = I18n.t('views.notifications.offender_needs_a_com.ldu_emailed', date: format_date(date_sent))
      href = '#com-name'
      expect(ldu_warning).to have_link(text, href: href)
    end
  end

  context 'when an email has not been sent' do
    it 'says "You must contact the community probation office"' do
      expect(title).to eq(I18n.t('views.notifications.offender_needs_a_com.must_contact_ldu'))
    end

    it 'says a supporting COM is needed' do
      text = I18n.t('views.notifications.offender_needs_a_com.com_needed')
      href = '#com-name'
      expect(com_warning).to have_link(text, href: href)
    end

    context 'when the LDU email address is unknown' do
      let(:ldu) { nil }

      it 'says the LDU cannot be contacted' do
        text = I18n.t('views.notifications.offender_needs_a_com.ldu_uncontactable')
        href = '#com-name'
        expect(ldu_warning).to have_link(text, href: href)
      end
    end

    context 'when we know the LDU email address' do
      it 'does not warn that the LDU is un-contactable' do
        expect(ldu_warning).to be_empty
      end
    end
  end
end
