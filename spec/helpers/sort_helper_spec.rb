require 'rails_helper'

class RequestMock
  def original_url; end
end

RSpec.describe SortHelper do
  let(:request) { RequestMock.new }

  it "Change the URL to include sorting if not present" do
    allow(request).to receive(:original_url).and_return('/unallocated')
    result = sort_link('last_name')
    expect(result).to eq('/unallocated?sort=last_name+desc')
  end

  it "Change the URL to include sorting if present" do
    allow(request).to receive(:original_url).and_return('/unallocated?sort=earliest_release_date+asc')
    result = sort_link('last_name')
    expect(result).to eq('/unallocated?sort=last_name+asc')
  end

  it "Change the URL to invert sorting if already present and asc" do
    allow(request).to receive(:original_url).and_return('/unallocated?sort=last_name+asc')
    result = sort_link('last_name')
    expect(result).to eq('/unallocated?sort=last_name+desc')
  end

  it "Change the URL to invert sorting if already present and desc" do
    allow(request).to receive(:original_url).and_return('/unallocated?sort=last_name+desc')
    result = sort_link('last_name')
    expect(result).to eq('/unallocated?sort=last_name+asc')
  end

  it "Change the URL to include anchor tag" do
    allow(request).to receive(:original_url).and_return('/unallocated?sort=last_name+desc')
    result = sort_link('last_name', anchor: 'anchortag')
    expect(result).to eq('/unallocated?sort=last_name+asc#anchortag')
  end

  it "raises an error when generating the link if the field is not sortable" do
    expect {
      sort_link('invalid_field')
    }.to raise_error(ArgumentError, "`invalid_field` is not an allowed sortable field")
  end

  it "raises an error when generating the arrow if the field is not sortable" do
    expect {
      sort_arrow('invalid_field')
    }.to raise_error(ArgumentError, "`invalid_field` is not an allowed sortable field")
  end

  context 'when no controller default or sort parameter is supplied' do
    before do
      allow(request).to receive(:original_url).and_return('/unallocated')
    end

    it 'keeps the existing last-name sort indicators' do
      expect(sort_arrow('last_name')).to eq('<span class="app-sort-arrow">&#9650</span>')
      expect(sort_aria('last_name')).to eq('aria-sort="ascending"')
      expect(sort_arrow('handover_date')).to eq('')
    end
  end

  context 'when the controller supplies a default sort without a redirect' do
    before do
      allow(request).to receive(:original_url).and_return('/handovers?pom=user&page=2')
      params['sort'] = 'handover_date asc'
    end

    it 'toggles the default column to descending and preserves the query parameters' do
      expect(sort_link('handover_date')).to eq('/handovers?pom=user&page=2&sort=handover_date+desc')
    end

    it 'sorts a different column ascending' do
      expect(sort_link('offender_last_name')).to eq('/handovers?pom=user&page=2&sort=offender_last_name+asc')
    end

    it 'shows the ascending arrow on the default column' do
      expect(sort_arrow('handover_date')).to eq('<span class="app-sort-arrow">&#9650</span>')
      expect(sort_arrow('last_name')).to eq('')
    end

    it 'marks the default column as sorted ascending for accessibility' do
      expect(sort_aria('handover_date')).to eq('aria-sort="ascending"')
    end

    it 'preserves anchors when toggling the default column' do
      expect(sort_link('handover_date', anchor: 'upcoming')).to eq(
        '/handovers?pom=user&page=2&sort=handover_date+desc#upcoming'
      )
    end

    context 'when the URL has a blank sort parameter' do
      before do
        allow(request).to receive(:original_url).and_return('/handovers?sort=&pom=user')
      end

      it 'uses the controller default for the link and arrow' do
        expect(sort_link('handover_date')).to eq('/handovers?sort=handover_date+desc&pom=user')
        expect(sort_arrow('handover_date')).to eq('<span class="app-sort-arrow">&#9650</span>')
      end
    end

    context 'when the URL specifies a sort order' do
      before do
        allow(request).to receive(:original_url).and_return('/handovers?sort=offender_last_name+desc&pom=user')
        params['sort'] = 'offender_last_name desc'
      end

      it 'preserves the explicit sort for links, arrows and accessibility attributes' do
        expect(sort_link('offender_last_name')).to eq('/handovers?sort=offender_last_name+asc&pom=user')
        expect(sort_arrow('offender_last_name')).to eq('<span class="app-sort-arrow">&#9660</span>')
        expect(sort_aria('offender_last_name')).to eq('aria-sort="descending"')
        expect(sort_arrow('handover_date')).to eq('')
      end
    end
  end
end
