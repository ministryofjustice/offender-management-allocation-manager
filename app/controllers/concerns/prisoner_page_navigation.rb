# frozen_string_literal: true

module PrisonerPageNavigation
private

  def prisoner_page_source
    params[:from].presence_in(%w[allocation review_case]) || default_prisoner_page_source
  end

  def prisoner_page_path(prison_id:, prisoner_id:)
    case prisoner_page_source
    when 'allocation'
      prison_prisoner_allocation_path(prison_id, prisoner_id:)
    else
      prison_prisoner_review_case_details_path(prison_id:, prisoner_id:)
    end
  end

  def default_prisoner_page_source
    'review_case'
  end
end
