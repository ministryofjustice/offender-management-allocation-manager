# frozen_string_literal: true

require 'rails_helper'

describe 'prisoner routes', type: :routing do
  let(:womens_prison_code) { PrisonService::WOMENS_PRISON_CODES.first }
  let(:male_prison_code) { PrisonService::OPEN_PRISON_CODES.first }

  describe get: "/prisons/#{PrisonService::WOMENS_PRISON_CODES.first}/prisoners/allocated" do
    context 'with womens_estate switch on' do
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        test_strategy.switch!(:womens_estate, true)
      end

      after do
        test_strategy.switch!(:womens_estate, false)
      end

      it { is_expected.to route_to controller: 'female_prisoners', action: 'allocated', prison_id: womens_prison_code }
    end

    context 'without womens_estate switch' do
      it { is_expected.to route_to controller: 'summary', action: 'allocated', prison_id: womens_prison_code }
    end
  end

  describe get: '/prisons/LEI/prisoners/allocated' do
    it { is_expected.to route_to controller: 'summary', action: 'allocated', prison_id: 'LEI' }
  end
end
