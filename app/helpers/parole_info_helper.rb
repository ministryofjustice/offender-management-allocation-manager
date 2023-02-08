module ParoleInfoHelper
  def display_hearing_outcome?(parole_record)
    parole_record&.target_hearing_date.present? &&
    parole_record.target_hearing_date <= Time.zone.today &&
    parole_record&.hearing_outcome.present?
  end
end
