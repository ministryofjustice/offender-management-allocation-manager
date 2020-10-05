require 'rails_helper'

RSpec.describe "debugging/debugging", type: :view do
  let(:offender) do
    offender = build(:offender, firstName: 'John', lastName: 'Dory')
    offender.sentence = HmppsApi::SentenceDetail.new(
      sentence_start_date: Time.zone.today,
      automatic_release_date: Time.zone.today + 10.months,
      tariff_date: Date.new(2033, 8, 1),
      nomis_post_recall_release_date: Date.new(2028, 11, 8),
      licence_expiry_date: Date.new(2025, 10, 7))
    return offender
  end

  let(:prison) { build(:prison) }

  describe "debugging/debugging.html.erb" do
    it "displays offender full_name" do
      assign(:offender, OffenderPresenter.new(offender))
      assign(:prison, prison)

      render
      page = Nokogiri::HTML(rendered)
      full_name = page.css('#prisoner-information').css('#name').first
      expect(full_name.text).to match(/Dory, John/)
    end
  end

  describe "debugging/debugging.html.erb" do
    it "displays tariff date" do
      assign(:offender, OffenderPresenter.new(offender))
      assign(:prison, prison)

      render
      page = Nokogiri::HTML(rendered)
      tariff_date = page.css('#sentence-information').css('#tariff-date').first
      expect(tariff_date.text).to match '01/08/2033'
    end

    it "displays post recall release date" do
      assign(:offender, OffenderPresenter.new(offender))
      assign(:prison, prison)

      render
      page = Nokogiri::HTML(rendered)
      post_recall_release_date = page.css('#sentence-information').css('#post-recall-release-date').first
      expect(post_recall_release_date.text).to match '08/11/2028'
    end

    it "displays licence end date" do
      assign(:offender, OffenderPresenter.new(offender))
      assign(:prison, prison)

      render
      page = Nokogiri::HTML(rendered)
      licence_expiry_date = page.css('#sentence-information').css('#licence-expiry-date').first

      expect(licence_expiry_date.text).to match '07/10/2025'
    end
  end
end
