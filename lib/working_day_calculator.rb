require 'bank_holidays'
require 'business_time'

class WorkingDayCalculator
  def initialize(holidays = BankHolidays.dates)
    BusinessTime::Config.holidays = Set.new(holidays)
  end

  def working_days_between(date1, date2)
    date1.business_days_until(date2)
  end

  def self.working_days_between(date1, date2)
    new.working_days_between(date1, date2)
  end
end
