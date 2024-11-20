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
end
