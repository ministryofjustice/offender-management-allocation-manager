# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Prison, type: :model do
  describe '#active' do
    before do
      create(:allocation_history, prison: p1.code)
      create(:allocation_history, prison: p1.code)
      create(:allocation_history, prison: p2.code)
    end

    let(:p1) { create(:prison) }
    let(:p2) { create(:prison) }

    it 'only lists prisons with allocations' do
      expect(described_class.active.map(&:code)).to match_array [p1, p2].map(&:code)
    end
  end

  describe '#womens?' do
    context 'with a male prison' do
      let(:prison) { create(:prison) }

      it 'is false' do
        expect(prison.womens?).to eq(false)
      end
    end

    context 'with a female prison' do
      let(:prison) { create(:womens_prison) }

      it 'is true' do
        expect(prison.womens?).to eq(true)
      end
    end
  end

  describe '#unfiltered_offenders' do
    subject { described_class.new(code: 'LEI').unfiltered_offenders }

    it "get first page of offenders for a specific prison",
       vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_first_page_spec' } do
      offender_array = subject.first(9)
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to eq(9)
    end

    it "get last page of offenders for a specific prison", vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_last_page_spec' } do
      offender_array = subject.to_a
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to be > 800
    end

    context 'when recall flag set' do
      let(:offenders) { build_list(:nomis_offender, 2, recall: true) }

      before do
        stub_auth_token
        stub_offenders_for_prison('LEI', offenders)
        create(:offender, nomis_offender_id: offenders.first.fetch(:offenderNo))
      end

      it 'populates the recall flag' do
        expect(subject.map(&:recalled?)).to eq [true, true]
      end

      it 'creates the missing offender object' do
        expect(subject.count).to eq(2)
        expect(Offender.count).to eq(2)
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
        stub_request(:get, "#{ApiHelper::T3}/locations/description/LEI/inmates?convictedStatus=Convicted").
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

        stub_offender_categories(offenders)
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
        stub_request(:get, "#{ApiHelper::T3}/locations/description/LEI/inmates?convictedStatus=Convicted").
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

        stub_offender_categories(offenders)
      end

      it 'fetches one page only' do
        expect(subject.count).to eq(200)
      end
    end

    describe 'Validations' do
      subject {
        described_class.new(prison_type: 'mens_open',
                            code: 'ACI',
                            name: 'HMP Altcourse')
      }

      it "is not valid without a prison_type" do
        subject.prison_type = nil
        expect(subject).to be_invalid
      end

      it "is not valid without a code" do
        subject.code = nil
        expect(subject).to be_invalid
      end

      it 's code must be unique' do
        described_class.create(prison_type: 'mens_open',
                               code: 'ACI',
                               name: 'HMP Altcourse')

        expect(subject).to be_invalid
      end

      it 's name must be unique' do
        described_class.create(prison_type: 'mens_open',
                               code: 'AGI',
                               name: 'HMP Altcourse')

        expect(subject).to be_invalid
      end

      it "is valid when all values are present" do
        expect(subject).to be_valid
      end
    end

    describe 'Associations with PomDetail' do
      let!(:prison) { create(:prison) }

      before do
        create_list(:pom_detail, 5, prison: prison)
      end

      it 'has many pom details' do
        expect(described_class.find(prison.code).pom_details.size).to be(5)
      end
    end
  end
end
