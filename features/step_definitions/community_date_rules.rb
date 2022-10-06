Given(/^a determinate NPS (?:\w+|) ?case$/) do
  @sentence_start_date = Date.new(2022, 9, 1)
end

Given(/^conditional release date is (\d+) months (\d+) days after sentence start date$/) do |crd_months, crd_days|
  @conditional_release_date = @sentence_start_date + crd_months.months + crd_days.days
end

Given(/^automatic release date is (\d+) months (\d+) days after sentence start date$/) do |num_months, num_days|
  @automatic_release_date = @sentence_start_date + num_months.months + num_days.days
end

When(/^community dates are calculated$/) do
  @community_dates = Handover::HandoverDateRules.determinate_nps_community_dates(
    conditional_release_date: @conditional_release_date,
    automatic_release_date: @automatic_release_date,
    sentence_start_date: @sentence_start_date)
end

Then(/^COM allocated date is set (\d+) months (\d+) days before conditional release date$/) do |num_months, num_days|
  expect(@community_dates.com_allocated_date).to eq(@conditional_release_date - num_months.months - num_days.days)
end

Then(/^COM responsible date is set (\d+) months (\d+) days before conditional release date$/) do |num_months, num_days|
  expect(@community_dates.com_responsible_date).to eq(@conditional_release_date - num_months.months - num_days.days)
end

Then(/^COM allocated date is set (\d+) months (\d+) days before automatic release date$/) do |num_months, num_days|
  expect(@community_dates.com_allocated_date).to eq(@automatic_release_date - num_months.months - num_days.days)
end

Then(/^COM responsible date is set (\d+) months (\d+) days before automatic release date$/) do |num_months, num_days|
  expect(@community_dates.com_responsible_date).to eq(@automatic_release_date - num_months.months - num_days.days)
end
