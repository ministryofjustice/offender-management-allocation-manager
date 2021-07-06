# frozen_string_literal: true

class DashboardController < PrisonsApplicationController
  def index
    if @is_spo
      render 'spo_dashboard'
    else
      render 'pom_dashboard'
    end
  end
end
