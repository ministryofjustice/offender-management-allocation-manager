# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HelpStep, type: :model do
  subject { described_class }

  let(:data) do
    [
      subject::Data.new(0, 'Overview'),
      subject::Data.new(1, 'List new staff members’ details'),
      subject::Data.new(2, 'Set up access in Digital Prison Services'),
      subject::Data.new(3, 'Set up staff in NOMIS'),
      subject::Data.new(4, 'Update POM profiles'),
      subject::Data.new(5, 'Update prisoner information'),
      subject::Data.new(6, 'Start making allocations')
    ]
  end

  describe '.all' do
    it 'returns all data' do
      expect(subject.all).to eq(data)
    end
  end

  describe '.find' do
    (0..6).each do |id|
      context "with id #{id}" do
        let(:id) { id }

        it "returns data with id #{id}" do
          expect(subject.find(id)).to eq(data[id])
        end
      end
    end
  end
end
