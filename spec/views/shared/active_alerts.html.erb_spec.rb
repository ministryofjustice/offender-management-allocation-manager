require 'rails_helper'

RSpec.describe 'shared/_active_alerts', type: :view do
  subject(:page) { Nokogiri::HTML(rendered) }

  context 'when alerts are unavailable' do
    before do
      render partial: 'shared/active_alerts', locals: { alerts: nil, offender_no: 'A1234AA' }
    end

    it 'shows the unavailable message' do
      expect(page.text).to include('This information is currently unavailable. Try again later.')
    end
  end

  context 'when there are no alerts' do
    before do
      render partial: 'shared/active_alerts', locals: { alerts: [], offender_no: 'A1234AA' }
    end

    it 'shows none' do
      expect(page.text).to include('None')
    end
  end

  context 'when alerts are present' do
    before do
      render partial: 'shared/active_alerts', locals: { alerts: ['ACCT open', 'Risk to staff'], offender_no: 'A1234AA' }
    end

    it 'renders each alert as a list item' do
      expect(page.css('li').map(&:text)).to eq(['ACCT open', 'Risk to staff'])
    end
  end
end
