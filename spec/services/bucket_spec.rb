require 'rails_helper'

describe Bucket do
  it "can retrieve last n" do
    b = described_class.new([])
    (1..5).each do |num|
      b << num
    end
    expect(b.count).to be(5)
    expect(b.to_a).to eq([1, 2, 3, 4, 5])
  end

  it "can try to retrieve last n if we have an empty bucket" do
    b = described_class.new([])
    expect(b.count).to be(0)
    expect(b.to_a).to eq([])
  end

  it "can sort its items by default ASC" do
    b = described_class.new([:last_name])
    b << OpenStruct.new(last_name: "Z")
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    expect(b.count).to be(3)

    b.sort_bucket!(:last_name)
    expect(b.map(&:last_name)).to eq(['A', 'M', 'Z'])
  end

  it "can sort its items DESC" do
    b = described_class.new([:last_name])
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.count).to be(3)

    b.sort_bucket!(:last_name, :desc)
    expect(b.map(&:last_name)).to eq(['Z', 'M', 'A'])
  end

  it "can't sort by made up field, using defaults" do
    b = described_class.new([])
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.count).to be(3)

    b.sort_bucket!(:test, :desc)
    expect(b.map(&:last_name)).to eq(['A', 'M', 'Z'])
  end

  it "when told can't sort by made up field" do
    b = described_class.new([:last_name])
    b << OpenStruct.new(last_name: "A")
    b << OpenStruct.new(last_name: "M")
    b << OpenStruct.new(last_name: "Z")
    expect(b.count).to be(3)

    b.sort_bucket!(:test, :desc)
    expect(b.map(&:last_name)).to eq(['A', 'M', 'Z'])
  end

  it 'can sort dates containing nulls' do
    b = described_class.new([:earliest_release_date])
    b << OpenStruct.new(
      last_name: "A",
      earliest_release_date: nil
    )
    b << OpenStruct.new(
      last_name: "A",
      earliest_release_date: Date.new(2000, 1, 1)
    )
    b.sort_bucket!(:earliest_release_date)
    expect(b.map(&:earliest_release_date)).to eq([nil, Date.new(2000, 1, 1)])

    b.sort_bucket!(:earliest_release_date, :desc)
    expect(b.map(&:earliest_release_date)).to eq([Date.new(2000, 1, 1), nil])
  end
end
