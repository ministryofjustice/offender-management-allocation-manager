module Components
  module DetailsHelper
    def detail_component(summary, &block)
      tag.details(class: %w[govuk-details], data: { module: 'govuk-details' }) do
        summary_markup = tag.summary(class: %w[details__summary]) do
          tag.span(summary, class: %w[govuk-details__summary-text])
        end

        details_markup = tag.div(capture(&block), class: %w[govuk-details__text])

        summary_markup + details_markup
      end
    end
  end
end
