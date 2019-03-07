require 'rails_helper'

describe PageMeta, model: true do
  it 'handles pages at the start' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 612
      p.total_pages = 62
      p.number = 1
      p.items_on_page = 10
    }

    expect(meta.pages).to match_array([1, 2, nil, 62])
  end

  it 'handles pages at the end' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 612
      p.total_pages = 62
      p.number = 62
      p.items_on_page = 10
    }

    expect(meta.pages).to match_array([1, nil, 61, 62])
  end

  it 'handles pages in the middle' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 612
      p.total_pages = 62
      p.number = 21
      p.items_on_page = 10
    }

    expect(meta.pages).to match_array([1, nil, 20, 21, 22, nil, 62])
  end

  it 'handles the page 3 in' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 612
      p.total_pages = 62
      p.number = 3
      p.items_on_page = 10
    }

    expect(meta.pages).to match_array([1, 2, 3, 4, nil, 62])
  end

  it 'handles the page 3 from the end' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 150
      p.total_pages = 15
      p.number = 13
      p.items_on_page = 10
    }

    expect(meta.pages).to match_array([1, nil, 12, 13, 14, 15])
  end

  it 'handles a single page' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 9
      p.total_pages = 1
      p.number = 1
      p.items_on_page = 9
    }

    expect(meta.pages).to match_array([1])
  end

  it 'handles missing data' do
    meta = PageMeta.new.tap { |p|
      p.size = 10
      p.total_elements = 0
      p.total_pages = 0
      p.number = 0
      p.items_on_page = 0
    }

    expect(meta.record_range).to eq('0 - 0')
    expect(meta.current_page).to eq(0)
    expect(meta.pages).to eq([])
    expect(meta.previous?).to be false
    expect(meta.next?).to be false
  end
end
