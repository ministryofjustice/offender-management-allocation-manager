class NamedDate
  def initialize(date, name)
    raise ArgumentError 'Name cannot be blank' if name.blank?

    @name = name
    @date = date
  end

  # Custom constructor is like .new except returns nil if date is nil
  def self.[](date, name)
    return nil if date.nil?

    new(date, name)
  end

  attr_reader :name, :date

  def <=>(other)
    date <=> other.date
  end

  def ==(other)
    [date, name] == [other.date, other.name]
  end

  def inspect
    "#<NamedDate:#{date.iso8601} (#{name})>"
  end

  def to_h
    { 'name' => name, 'date' => date }
  end
end
