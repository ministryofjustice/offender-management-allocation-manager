# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prison, type: :model do
  describe '#active' do
    before do
      create(:allocation, prison: p1.code)
      create(:allocation, prison: p1.code)
      create(:allocation, prison: p2.code)
    end

    let(:p1) { build(:prison) }
    let(:p2) { build(:prison) }

    it 'only lists prisons with allocations' do
      expect(described_class.active.map(&:code)).to match_array [p1, p2].map(&:code)
    end
  end

  describe '#all' do
    let(:p1) { build(:prison) }
    let(:p2) { build(:womens_prison) }

    it 'includes all male prisons' do
      expect(described_class.all.map(&:code)).to include(p1.code)
    end

    it 'includes all womens prisons' do
      expect(described_class.all.map(&:code)).to include(p2.code)
    end
  end

  describe '#womens?' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }

    before do
      test_strategy.switch!(:womens_estate, true)
    end

    after do
      test_strategy.switch!(:womens_estate, false)
    end

    context 'with a male prison' do
      let(:prison) { build(:prison) }

      it 'is false' do
        expect(prison.womens?).to eq(false)
      end
    end

    context 'with a female prison' do
      let(:prison) { build(:womens_prison) }

      it 'is true' do
        expect(prison.womens?).to eq(true)
      end
    end
  end

  describe '#offenders' do
    subject { described_class.new("LEI").offenders }

    it "get first page of offenders for a specific prison",
       vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_first_page_spec' } do
      offender_array = subject.first(9)
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to eq(9)
      expect(offender_array.first).to be_kind_of(HmppsApi::OffenderSummary)
    end

    it "get last page of offenders for a specific prison", vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_last_page_spec' } do
      offender_array = subject.to_a
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to be > 800
      expect(offender_array.first).to be_kind_of(HmppsApi::OffenderSummary)
    end

    context 'when recall flag set' do
      let(:offenders) { build_list(:nomis_offender, 2, recall: true) }

      before do
        stub_auth_token
        stub_offenders_for_prison('LEI', offenders)
      end

      it 'populates the recall flag' do
        expect(subject.map(&:recalled?)).to eq [true, true]
      end
    end

    context 'when the search API misses someone' do
      let(:offenders) {
        [build(:nomis_offender, recall: true),
         build(:nomis_offender, recall: false),
         build(:nomis_offender, recall: true)]
      }
      let(:offender_nos) { offenders.map { |o| o.fetch(:offenderNo) } }

      before do
        stub_auth_token
        stub_request(:get, "#{ApiHelper::T3}/locations/description/LEI/inmates?convictedStatus=Convicted&returnCategory=true").
          with(
            headers: {
              'Page-Limit' => '200',
              'Page-Offset' => '0',
            }).
          to_return(body: offenders.to_json)

        stub_request(:post, "#{ApiHelper::T3_SEARCH}/prisoner-numbers").
          with(
            body: { prisonerNumbers: offender_nos }.to_json
          ).
          to_return(body: offenders.first(2).map { |o|
            { prisonerNumber: o.fetch(:offenderNo),
              recall: o.fetch(:recall) }
          }.to_json)

        stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=true&movementTypes=TAP").
          with(body: offender_nos.to_json).
          to_return(body: [].to_json)

        bookings = offenders.map { |offender| { 'bookingId' => offender.fetch(:bookingId), 'sentenceDetail' => offender.fetch(:sentence) } }
        stub_request(:post, "#{ApiHelper::T3}/offender-sentences/bookings").
          with(body: offenders.map { |o| o.fetch(:bookingId) }.to_json).
          to_return(body: bookings.to_json)

        stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN").
            with(
              body: offenders.first(2).map { |o| o.fetch(:offenderNo) }.to_json,
            ).
            to_return(body: [].to_json)

        allow(HmppsApi::ComplexityApi).to receive(:get_complexities).with(offender_nos).and_return(
          offenders.map { |offender| [offender.fetch(:offenderNo), offender.fetch(:complexityLevel)] }.to_h
        )
      end

      it 'skips the missing offender record' do
        expect(subject.map(&:offender_no)).to eq(offender_nos.first(2))
      end
    end

    context 'when there are exactly 200 offenders' do
      let(:offenders) { build_list(:nomis_offender, 200) }
      let(:offender_nos) { offenders.map { |o| o.fetch(:offenderNo) } }

      before do
        stub_auth_token
        stub_request(:get, "#{ApiHelper::T3}/locations/description/LEI/inmates?convictedStatus=Convicted&returnCategory=true").
          with(
            headers: {
              'Page-Limit' => '200',
              'Page-Offset' => '0',
            }).
          to_return(body: offenders.to_json)

        stub_request(:post, "#{ApiHelper::T3_SEARCH}/prisoner-numbers").
          with(
            body: { prisonerNumbers: offender_nos }.to_json
          ).
          to_return(body: offenders.map { |o|
                            { prisonerNumber: o.fetch(:offenderNo),
                                                recall: o.fetch(:recall) }
                          }                          .to_json)

        stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=true&movementTypes=TAP").
          with(body: offender_nos.to_json).
          to_return(body: [].to_json)

        bookings = offenders.map { |offender| { 'bookingId' => offender.fetch(:bookingId), 'sentenceDetail' => offender.fetch(:sentence) } }
        stub_request(:post, "#{ApiHelper::T3}/offender-sentences/bookings").
          with(body: offenders.map { |o| o.fetch(:bookingId) }.to_json).
          to_return(body: bookings.to_json)

        stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN").
            with(
              body: offenders.map { |o| o.fetch(:offenderNo) }.to_json,
                ).
            to_return(body: [].to_json)
        allow(HmppsApi::ComplexityApi).to receive(:get_complexities).with(offender_nos).and_return(
          offenders.map { |offender| [offender.fetch(:offenderNo), offender.fetch(:complexityLevel)] }.to_h
        )
      end

      it 'fetches one page only' do
        expect(subject.count).to eq(200)
      end
    end
  end
end
