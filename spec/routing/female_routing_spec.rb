# frozen_string_literal: true

require 'rails_helper'

describe 'prisoner routes', type: :routing do
  let(:womens_prison_code) { PrisonService::WOMENS_PRISON_CODES.first }
  let(:male_prison_code) { PrisonService::OPEN_PRISON_CODES.first }

  describe get: "/prisons/#{PrisonService::WOMENS_PRISON_CODES.first}/prisoners/T5644GY/new_missing_info" do
    context 'with womens_estate switch on' do
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        test_strategy.switch!(:womens_estate, true)
      end

      after do
        test_strategy.switch!(:womens_estate, false)
      end

      it { is_expected.to route_to controller: 'female_missing_infos', action: 'new', prison_id: womens_prison_code, prisoner_id: "T5644GY" }
    end

    context 'without womens_estate switch' do
      it { is_expected.to route_to controller: 'case_information', action: 'new', prison_id: womens_prison_code, prisoner_id: "T5644GY" }
    end
  end

  describe get: "/prisons/LEI/prisoners/T5644GY/new_missing_info" do
    it { is_expected.to route_to controller: 'case_information', action: 'new', prison_id: 'LEI', prisoner_id: "T5644GY" }
  end
end
