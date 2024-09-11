# frozen_string_literal: true

require "rails_helper"

describe HmppsApi::ComplexityApi do
  let(:api_host) { Rails.configuration.complexity_api_host }

  describe '#get_complexity' do
    let(:endpoint) { "#{api_host}/v1/complexity-of-need/offender-no/#{offender_no}" }

    before do
      stub_request(:get, endpoint).to_return(status:, body:)
    end

    context 'when item is present' do
      let(:offender_no) { 'G0276VC' }
      let(:status) { 200 }
      let(:body) do
        {
          offenderNo: "G0276VC",
          level: "high",
          createdTimeStamp: "2021-03-11T11:05:10.493Z",
          sourceSystem: "testing",
          active: true
        }.to_json
      end

      it { expect(described_class.get_complexity 'G0276VC').to eq('high') }
    end

    context 'when item is absent' do
      let(:offender_no) { 'T0276VC' }
      let(:status) { 404 }
      let(:body) { nil }

      it { expect(described_class.get_complexity 'T0276VC').to eq(nil) }
    end
  end

  describe '#save' do
    let(:endpoint) { "#{api_host}/v1/complexity-of-need/offender-no/#{offender_no}" }
    let(:offender_no) { 'S0005FT' }
    let(:body) do
      {
        offenderNo: "S0005FT",
        level: "high",
        createdTimeStamp: "2021-03-11T11:05:10.493Z",
        sourceSystem: "testing",
        active: true
      }.to_json
    end

    before do
      stub_request(:post, endpoint).with(
        body: { level: 'high', sourceUser: 'SDICKS_GEN', notes: 'Happy Feet' }
      ).to_return(body:)
    end

    scenario 'happy path' do
      expect(
        described_class.save(offender_no, level: 'high', username: 'SDICKS_GEN', reason: 'Happy Feet')
      ).to eq(JSON.parse(body))
    end
  end

  describe '#get_complexities' do
    let(:endpoint) { "#{api_host}/v1/complexity-of-need/multiple/offender-no" }
    let(:body) do
      [
        { "offenderNo": "G0276VC", "level": "high", "createdTimeStamp": "2021-03-11T11:05:10.493Z", "sourceSystem": "testing", "active": true },
        { "offenderNo": "T0000FT", "level": "high", "createdTimeStamp": "2021-03-17T20:54:55.902Z", "sourceSystem": "hardcoded-oauth-client-id", "active": true }
      ].to_json
    end

    before do
      stub_request(:post, endpoint).with(body: offender_nos).to_return(body:)
    end

    context 'when all offenders are found' do
      let(:offender_nos) { %w[G0276VC T0000FT] }

      it {
        expect(described_class.get_complexities(offender_nos))
          .to eq('G0276VC' => 'high', 'T0000FT' => 'high')
      }
    end

    context 'when some offenders are not found' do
      let(:offender_nos) { %w[G0276VC T0000FT X00887XX] }

      it {
        expect(described_class.get_complexities(offender_nos))
          .to eq('G0276VC' => 'high', 'T0000FT' => 'high')
      }
    end
  end

  describe '#get_history' do
    let(:endpoint) { "#{api_host}/v1/complexity-of-need/offender-no/#{offender_no}/history" }
    let(:offender_no) { 'S0004FT' }
    let(:body) do
      [
        { "offenderNo": "S0004FT", "level": "high", "createdTimeStamp": "2021-03-18T14:35:20.046Z", "sourceUser": "SDICKS_GEN", "sourceSystem": "hardcoded-oauth-client-id", "notes": "Happy Feet", "active": true },
        { "offenderNo": "S0004FT", "level": "high", "createdTimeStamp": "2021-03-18T14:34:58.551Z", "sourceUser": "SDICKS_GEN", "sourceSystem": "hardcoded-oauth-client-id", "notes": "Happy Feet", "active": true },
        { "offenderNo": "S0004FT", "level": "low", "createdTimeStamp": "2021-03-18T14:33:28.364Z", "sourceUser": "SDICKS_GEN", "sourceSystem": "hardcoded-oauth-client-id", "notes": "Happy Feet", "active": true }
      ].to_json
    end

    before do
      stub_request(:get, endpoint).to_return(body:)
    end

    scenario 'happy path' do
      expect(described_class.get_history(offender_no)).to eq(
        [
          { createdTimeStamp: Time.parse('2021-03-18T14:33:28.364Z'), level: 'low', sourceUser: 'SDICKS_GEN', notes: 'Happy Feet' },
          { createdTimeStamp: Time.parse('2021-03-18T14:34:58.551Z'), level: 'high', sourceUser: 'SDICKS_GEN', notes: 'Happy Feet' },
          { createdTimeStamp: Time.parse('2021-03-18T14:35:20.046Z'), level: 'high', sourceUser: 'SDICKS_GEN', notes: 'Happy Feet' },
        ])
    end
  end

  describe '#inactivate' do
    let(:endpoint) { "#{api_host}/v1/complexity-of-need/offender-no/#{offender_no}/inactivate" }
    let(:offender_no) { 'S0005FT' }
    let(:body) do
      { "offenderNo": "S0005FT", "level": "high", "createdTimeStamp": "2022-08-09T10:29:51.814Z", "sourceUser": "SDICKS_GEN", "sourceSystem": "manage-pom-cases-api-3", "notes": "Happy Feet", "active": false }.to_json
    end

    before do
      stub_request(:put, endpoint).to_return(body:)
    end

    scenario 'item present' do
      expect(
        described_class.inactivate(offender_no)
      ).to eq(JSON.parse(body))
    end
  end
end
