# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sorting do
  controller(ApplicationController) do
    include Sorting # rubocop:disable RSpec/DescribedClass
  end

  let(:date1) { Date.new(2023, 1, 1) }
  let(:date2) { Date.new(2023, 2, 1) }
  let(:date3) { Date.new(2023, 3, 1) }

  let(:items) do
    [
      double('Item', last_name: 'Smith', handover_date: date1),
      double('Item', last_name: 'Jones', handover_date: date2),
      double('Item', last_name: 'Brown', handover_date: date3),
    ]
  end

  describe '#sort_collection' do
    it 'sorts by last_name ascending' do
      sorted_items = controller.sort_collection(items, default_sort: :last_name, default_direction: :asc)
      expect(sorted_items.map(&:last_name)).to eq %w[Brown Jones Smith]
    end

    it 'sorts by last_name descending' do
      sorted_items = controller.sort_collection(items, default_sort: :last_name, default_direction: :desc)
      expect(sorted_items.map(&:last_name)).to eq %w[Smith Jones Brown]
    end

    it 'sorts by handover_date ascending' do
      sorted_items = controller.sort_collection(items, default_sort: :handover_date, default_direction: :asc)
      expect(sorted_items.map(&:handover_date)).to eq [date1, date2, date3]
    end

    it 'sorts by handover_date descending' do
      sorted_items = controller.sort_collection(items, default_sort: :handover_date, default_direction: :desc)
      expect(sorted_items.map(&:handover_date)).to eq [date3, date2, date1]
    end

    it 'returns the original collection if the field is not sortable' do
      sorted_items = controller.sort_collection(items, default_sort: :invalid_field, default_direction: :asc)
      expect(sorted_items).to eq items
    end
  end

  describe '#sort_and_paginate' do
    let(:paginated_items) { controller.sort_and_paginate(items, default_sort: :last_name, default_direction: :asc) }

    context 'when on page 1' do
      it 'sorts and paginates the collection' do
        allow(controller).to receive(:params).and_return({ 'page' => 1 })
        expect(paginated_items.map(&:last_name)).to eq %w[Brown Jones Smith]
      end
    end

    context 'when on page 2' do
      it 'sorts and paginates the collection' do
        allow(controller).to receive(:params).and_return({ 'page' => 2 })
        expect(paginated_items.map(&:last_name)).to eq []
      end
    end
  end
end
