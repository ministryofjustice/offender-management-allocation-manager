require 'rails_helper'

RSpec.describe "debugging/debugging", type: :view do
  let(:offender) do
    build(:offender, firstName: 'John', lastName: 'Dory').tap { |offender|
      offender.sentence = build(:sentence_detail,
                                sentenceStartDate: Time.zone.today,
                                automaticReleaseDate: Time.zone.today + 10.months,
                                tariffDate: Date.new(2033, 8, 1),
                                postRecallReleaseDate: Date.new(2028, 11, 8),
                                licenceExpiryDate: Date.new(2025, 10, 7))
    }
  end

  let(:prison) { build(:prison) }

  before do
    assign(:offender, offender)
    assign(:prison, prison)

    render
  end

  it "displays offender full_name" do
    page = Nokogiri::HTML(rendered)
    full_name = page.css('#prisoner-information').css('#name').first
    expect(full_name.text).to match(/Dory, John/)
  end

  it "displays tariff date" do
    page = Nokogiri::HTML(rendered)
    tariff_date = page.css('#sentence-information').css('#tariff-date').first
    expect(tariff_date.text).to match '01/08/2033'
  end

  it "displays post recall release date" do
    page = Nokogiri::HTML(rendered)
    post_recall_release_date = page.css('#sentence-information').css('#post-recall-release-date').first
    expect(post_recall_release_date.text).to match '08/11/2028'
  end

  it "displays licence end date" do
    page = Nokogiri::HTML(rendered)
    licence_expiry_date = page.css('#sentence-information').css('#licence-expiry-date').first

    expect(licence_expiry_date.text).to match '07/10/2025'
  end
end
