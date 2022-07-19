class HelpController < ApplicationController
  layout 'errors_and_contact'

  def show
    page = params[:page]
    unless File.file?(Rails.root.join("app/views/help/#{page}.html.erb"))
      logger.warn("Nonexistent help page #{page.inspect}")
      redirect_to '/404'
      return
    end

    render page
  end
end
