Given(/^a determinate NPS (?:\w+|) ?case$/) do
  @sentence_start_date = Date.new(2022, 9, 1)
end

Given(/^CRD is (\d+) months (\d+) days after sentence start$/) do |crd_months, crd_days|
  @conditional_release_date = @sentence_start_date + crd_months.months + crd_days.days
end

Given(/^ARD is (\d+) months (\d+) days after sentence start$/) do |num_months, num_days|
  @automatic_release_date = @sentence_start_date + num_months.months + num_days.days
end

When(/^handover is calculated$/) do
  @community_dates = Handover::HandoverDateRules.calculate_handover_dates(
    nomis_offender_id: 'AB1234D',
    conditional_release_date: @conditional_release_date,
    automatic_release_date: @automatic_release_date,
    sentence_start_date: @sentence_start_date)
end

Then(/^handover date is (\d+) months (\d+) days before CRD$/) do |num_months, num_days|
  expected_handover = @conditional_release_date - num_months.months - num_days.days
  expect(@community_dates.handover_date).to eq(expected_handover)
end

Then(/^handover date is (\d+) months (\d+) days before ARD$/) do |num_months, num_days|
  expected_handover = @automatic_release_date - num_months.months - num_days.days
  expect(@community_dates.handover_date).to eq(expected_handover)
end

Then(/^reason is ([a-z_]+)$/) do |expected_reason|
  expect(@community_dates.reason).to eq expected_reason.to_sym
end
