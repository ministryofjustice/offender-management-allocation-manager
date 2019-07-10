# frozen_string_literal: true

class Summary
  attr_accessor :offenders
  attr_accessor :allocated_total, :unallocated_total, :pending_total
  attr_accessor :page_count

  def initialize(summary_type)
    @summary_type = summary_type
  end

  def page_meta(current_page)
    new_page_meta(current_page).tap{ |p|
      p.total_pages = page_count
      p.items_on_page = offenders.count
      p.total_elements = total_for_summary_type
    }
  end

private

  def total_for_summary_type
    return allocated_total if @summary_type == :allocated
    return unallocated_total if @summary_type == :unallocated

    pending_total if @summary_type == :pending
  end

  def new_page_meta(current_page)
    PageMeta.new.tap{ |p|
      p.size = 10
      p.number = current_page
    }
  end
end
