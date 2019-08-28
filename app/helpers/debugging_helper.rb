module DebuggingHelper
  def agency(code)
    if PrisonService::PRISONS.include?(code)
      PrisonService.name_for(code)
    else
      'Location outside the prison estate'
    end
  end
end
