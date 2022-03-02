# frozen_string_literal: true

class HelpStep
  Data = Struct.new(
    :id,
    :heading
  ) do
    def url
      "help_step#{id}"
    end
  end

  @data = [
    'Overview',
    'List new staff members’ details',
    'Set up access in Digital Prison Services',
    'Set up staff in NOMIS',
    'Update POM profiles',
    'Update prisoner information',
    'Start making allocations'
  ].map.with_index do |heading, index|
    Data.new(
      index,
      heading
    )
  end

  def self.all
    @data
  end

  def self.find(id)
    @data[id]
  end
end
