FactoryBot.define do
  factory :offender_email_opt_out do
    sequence(:staff_member_id) { |n| "%06i" % n }
    offender_email_type { OffenderEmailOptOut::FIELDS.sample }
  end
end
