# frozen_string_literal: true

module CaseHistoryTimelineHelper
  TIMELINE_SECTION_SELECTORS = %w[.app-case-history__episode .govuk-grid-row].freeze

  def timeline_titles
    timeline_nodes('.moj-timeline__title').map { |node| node.text.strip }
  end

  def expect_timeline_titles(*titles)
    aggregate_failures do
      titles.each do |title|
        expect(timeline_titles).to include(title)
      end
    end
  end

  def within_timeline_section(heading, &block)
    within(find_timeline_section(heading), &block)
  end

  def find_timeline_item(text, &matcher)
    items = timeline_nodes('.moj-timeline__item').select { |item| item.text.include?(text) }
    item = matcher ? items.find { |candidate| matcher.call(candidate) } : items.first

    raise "Could not find timeline item matching #{text.inspect}" unless item

    item
  end

  def within_timeline_item(text, &block)
    within(find_timeline_item(text), &block)
  end

  def find_timeline_section(heading)
    section = TIMELINE_SECTION_SELECTORS
      .flat_map { |selector| all(selector) }
      .find { |candidate| candidate.has_css?('.govuk-heading-m', text: heading) }

    raise "Could not find timeline section for #{heading}" unless section

    section
  end

private

  def timeline_nodes(selector)
    if page.respond_to?(:all)
      page.all(selector)
    else
      page.css(selector)
    end
  end
end
