module Nomis
  class PageMeta
    include MemoryModel

    attribute :size, :integer
    attribute :total_elements, :integer
    attribute :total_pages, :integer
    attribute :number, :integer
  end
end
