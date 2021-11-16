# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::AssessmentApi do
  let(:api_host) { Rails.configuration.assessment_api_host }

  before do
    stub_auth_token
  end

  describe '.get_latest_oasys_date' do
    let(:offender_no) { 'A9346AC' }

    let(:stub_url) { "#{api_host}/offenders/nomisId/#{offender_no}/assessments/summary?assessmentStatus=COMPLETE" }

    context 'when there is one completed LAYER_3 OASys assessment' do
      # The last assessment date is the 'completed' field.
      # The test expects it to be a date object for consistency throughout the code base
      let(:completed_date) { '2012-12-10'.to_date }
      let(:latest_assessment) { build(:assessment_api_response, completed: completed_date) }

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: [
          latest_assessment].to_json)
      end

      it 'checks that the API has only been called once' do
        described_class.get_latest_oasys_date(offender_no)
        expect(a_request(:get, stub_url)).to have_been_made.once
      end

      it 'returns the date the assessment was completed for LAYER_3' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: "LAYER_3", completed: completed_date)
      end
    end

    context 'when there is one completed LAYER_1 OASys assessment' do
      # The last assessment date is the 'completed' field.
      # The test expects it to be a date object for consistency throughout the code base
      let(:completed_date) { '2012-12-10'.to_date }
      let(:latest_assessment) { build(:assessment_api_response, completed: completed_date, refAssessmentVersionCode: 'LAYER_1', assessmentType: 'LAYER_1') }

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: [
          latest_assessment].to_json)
      end

      it 'checks that the API has only been called once' do
        described_class.get_latest_oasys_date(offender_no)
        expect(a_request(:get, stub_url)).to have_been_made.once
      end

      it 'returns the date the assessment was completed for LAYER_1' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: "LAYER_1", completed: completed_date)
      end
    end

    context 'when there are multiple completed OASys assessments' do
      let(:old_layer_3_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_3', assessmentType: 'LAYER_3') }
      let(:old_layer_2_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_2', assessmentType: 'LAYER_2') }
      let(:old_layer_1_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_1', assessmentType: 'LAYER_1') }
      let(:latest_assessment) { build(:assessment_api_response, completed: Time.zone.now) }
      let(:all_assessments) { (old_layer_3_assessments + old_layer_2_assessments + old_layer_1_assessments + [latest_assessment]).shuffle }

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: all_assessments.to_json)
      end

      it 'returns the most recently completed assessment' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: "LAYER_3", completed: Time.zone.today)
      end
    end

    context 'when there are multiple completed but invalid OASys assessments to ignore' do
      let(:old_layer_3_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_5', assessmentType: 'LAYER_5') }
      let(:old_layer_2_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_2', assessmentType: 'LAYER_2') }
      let(:old_layer_1_assessments) { build_list(:assessment_api_response, 5, refAssessmentVersionCode: 'LAYER_4', assessmentType: 'LAYER_4') }
      let(:all_assessments) { (old_layer_3_assessments + old_layer_2_assessments + old_layer_1_assessments).shuffle }

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: all_assessments.to_json)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when there are no assessments (it returns an empty array)' do
      before do
        stub_request(:get, stub_url).to_return(status: 200, body: [].to_json)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when the offender is not found (status 404)' do
      before do
        stub_request(:get, stub_url).to_return(status: 404, body: {
          "status": 404,
          "developerMessage": "Offender not found for NOMIS, A1857ER"
        }.to_json)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when the offender is duplicated in oasys (status 409)' do
      before do
        stub_request(:get, stub_url).to_return(status: 409, body: {
          "status": 409,
          "developerMessage": "Offender duplicate found for NOMIS, A1857ER"
        }.to_json)
      end

      it 'returns 409 constant' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: Faraday::ConflictError, completed: nil)
      end
    end
  end
end
