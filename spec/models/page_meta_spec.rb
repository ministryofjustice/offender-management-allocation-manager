require 'rails_helper'

describe PageMeta, model: true do
  it 'handles missing data' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 0
      p.total_pages = 0
      p.number = 0
      p.items_on_page = 0
    }

    expect(meta.record_range).to eq('0 - 0')
    expect(meta.current_page).to eq(1)
    expect(meta.page_numbers).to eq([])
    expect(meta.previous?).to be false
    expect(meta.next?).to be false
  end

  it 'handles a single pages' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 10
      p.total_pages = 1
      p.number = 0
      p.items_on_page = 10
    }

    expect(meta.record_range).to eq('1 - 10')
    expect(meta.current_page).to eq(1)
    expect(meta.page_numbers).to eq(1..1)
    expect(meta.previous?).to be false
    expect(meta.next?).to be false
  end

  it 'handles less than 5 pages' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 30
      p.total_pages = 3
      p.number = 2
      p.items_on_page = 10
    }

    expect(meta.record_range).to eq('21 - 30')
    expect(meta.current_page).to eq(3)
    expect(meta.page_numbers).to eq(1..3)
    expect(meta.previous?).to be true
    expect(meta.next?).to be false
  end

  it 'handles lots of pages' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 1000
      p.total_pages = 100
      p.number = 99
      p.items_on_page = 10
    }

    expect(meta.record_range).to eq('991 - 1000')
    expect(meta.current_page).to eq(100)
    expect(meta.page_numbers).to eq(95..100)
    expect(meta.previous?).to be true
    expect(meta.next?).to be false
  end

  it 'handles showing a short last page' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 15
      p.total_pages = 2
      p.number = 1
      p.items_on_page = 5
    }

    expect(meta.record_range).to eq('11 - 15')
    expect(meta.current_page).to eq(2)
    expect(meta.page_numbers).to eq(1..2)
    expect(meta.previous?).to be true
    expect(meta.next?).to be false
  end

  it 'shows sliding window' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 200
      p.total_pages = 20
      p.number = 9
      p.items_on_page = 10
    }

    expect(meta.record_range).to eq('91 - 100')
    expect(meta.current_page).to eq(10)
    expect(meta.page_numbers).to eq(8..12)
    expect(meta.previous?).to be true
    expect(meta.next?).to be true
  end
end
