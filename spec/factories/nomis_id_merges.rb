FactoryBot.define do
  factory :nomis_id_merge do
    sequence(:old_nomis_id) { |n| "T#{n.to_s.rjust(4, '0')}AO" }
    sequence(:new_nomis_id) { |n| "T#{n.to_s.rjust(4, '0')}AN" }
  end
end
