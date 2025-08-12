# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomDetail, type: :model do
  let!(:prison) { create(:prison) }

  it { is_expected.to validate_presence_of(:nomis_staff_id) }
  it { expect(create(:pom_detail, prison: prison)).to validate_uniqueness_of(:nomis_staff_id).scoped_to(:prison_code) }
  it { is_expected.to validate_presence_of(:working_pattern).with_message('Select number of days worked') }
  it { is_expected.to validate_presence_of(:status) }

  describe '#hours_per_week=' do
    it 'converts hours to working pattern ratio' do
      subject.hours_per_week = 30
      expect(subject.working_pattern).to eq(0.8)
    end

    it 'converts full time hours to 1.0' do
      subject.hours_per_week = 37.5
      expect(subject.working_pattern).to eq(1.0)
    end

    it 'caps working pattern to 1.0 for hours greater than full time' do
      subject.hours_per_week = 40
      expect(subject.working_pattern).to eq(1.0)
    end
  end

  describe '#hours_per_week' do
    it 'converts working pattern to hours' do
      subject.working_pattern = 0.8
      expect(subject.hours_per_week).to eq(30.0)
    end

    it 'returns full time hours for full time pattern' do
      subject.working_pattern = 1.0
      expect(subject.hours_per_week).to eq(37.5)
    end
  end
end
