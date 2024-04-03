module AriaHelper
  def aria_current_page_for_tab(expected_tab, current_tab: @tab)
    if current_tab == expected_tab
      { current: "page" }
    else
      {}
    end
  end
end
