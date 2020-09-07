require 'rails_helper'

RSpec.describe Prison, type: :model do
  describe '#offenders' do
    subject { described_class.new("LEI").offenders }

    it "get first page of offenders for a specific prison",
       vcr: { cassette_name: :offender_service_offenders_by_prison_first_page_spec } do
      offender_array = subject.first(9)
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to eq(9)
      expect(offender_array.first).to be_kind_of(Nomis::OffenderSummary)
    end

    it "get last page of offenders for a specific prison", vcr: { cassette_name: :offender_service_offenders_by_prison_last_page_spec } do
      offender_array = subject.to_a
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to be > 800
      expect(offender_array.first).to be_kind_of(Nomis::OffenderSummary)
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
      end

      it 'fetches one page only' do
        expect(subject.count).to eq(200)
      end
    end
  end
end
