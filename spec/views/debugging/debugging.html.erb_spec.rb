require 'rails_helper'

RSpec.describe "debugging/debugging", type: :view do
  let(:offender) do
    build(:hmpps_api_offender, firstName: 'John', lastName: 'Dory').tap { |offender|
      offender.sentence = build(:sentence_detail,
                                sentenceStartDate: Time.zone.today,
                                automaticReleaseDate: Time.zone.today + 10.months,
                                tariffDate: Date.new(2033, 8, 1),
                                postRecallReleaseDate: Date.new(2028, 11, 8),
                                licenceExpiryDate: Date.new(2025, 10, 7))
    }
  end

  let(:prison) { create(:prison) }

  let(:page) { Nokogiri::HTML(rendered) }

  before do
    assign(:offender, offender)
    assign(:prison, prison)

    render
  end

  it "displays offender full_name" do
    full_name = page.css('#prisoner-information').css('#name').first
    expect(full_name.text).to match(/Dory, John/)
  end

  it "displays tariff date" do
    tariff_date = page.css('#sentence-information').css('#tariff-date').first
    expect(tariff_date.text).to match '01 Aug 2033'
  end

  it "displays post recall release date" do
    post_recall_release_date = page.css('#sentence-information').css('#post-recall-release-date').first
    expect(post_recall_release_date.text).to match '08 Nov 2028'
  end

  it "displays licence end date" do
    licence_expiry_date = page.css('#sentence-information').css('#licence-expiry-date').first

    expect(licence_expiry_date.text).to match '07 Oct 2025'
  end

  describe 'category label' do
    let(:key) { page.css('#category > td:nth-child(1)').text }
    let(:value) { page.css('#category > td:nth-child(2)').text.strip }

    context 'when the offender has a category' do
      let(:offender) { build(:hmpps_api_offender, category: build(:offender_category, :female_open, approvalDate: '17/06/2021'.to_date)) }

      it 'shows category details' do
        expect(key).to eq('Category')
        expect(value).to eq('Female Open (T) (since 17 Jun 2021)')
      end
    end

    context 'when category is unknown' do
      # This happens when an offender's category assessment hasn't been completed yet
      let(:offender) { build(:hmpps_api_offender, category: nil) }

      it 'shows "Unknown"' do
        expect(key).to eq('Category')
        expect(value).to eq('Unknown')
      end
    end
  end
end
