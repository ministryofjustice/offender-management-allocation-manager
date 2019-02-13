# The Bucket class is a simple data structure that can contain a fixed
# number of things. The initial capacity of the bucket is set on
# creation and once full, any attempts to put more items in the
# bucket will be ignored.
class Bucket
  attr_accessor :items

  def initialize(capacity)
    raise BucketCapacityException if capacity < 1

    @items = []
    @capacity = capacity
  end

  def <<(item)
    return if full?

    @items << item
  end

  def last(count)
    start_index = @items.count - count
    start_index = 0 if start_index < 0
    @items[start_index..-1]
  end

  def full?
    @items.count == @capacity
  end
end

class BucketCapacityException < RuntimeError; end
