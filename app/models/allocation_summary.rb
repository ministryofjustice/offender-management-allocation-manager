class AllocationSummary
  attr_accessor :allocated_offenders, :unallocated_offenders, :missing_info_offenders
  attr_accessor :allocated_total, :unallocated_total, :missing_info_total
  attr_accessor :allocated_page_count, :unallocated_page_count, :missing_page_count

  def allocated_page_meta(current_page)
    new_page_meta(current_page).tap{ |p|
      p.total_elements = allocated_total
      p.total_pages = allocated_page_count
      p.items_on_page = allocated_offenders.count
    }
  end

  def unallocated_page_meta(current_page)
    new_page_meta(current_page).tap{ |p|
      p.total_elements = unallocated_total
      p.total_pages = unallocated_page_count
      p.items_on_page = unallocated_offenders.count
    }
  end

  def missing_info_page_meta(current_page)
    new_page_meta(current_page).tap{ |p|
      p.total_elements = missing_info_total
      p.total_pages = missing_page_count
      p.items_on_page = missing_info_offenders.count
    }
  end

private

  def new_page_meta(current_page)
    PageMeta.new.tap{ |p|
      p.size = 10
      p.number = current_page
    }
  end
end
