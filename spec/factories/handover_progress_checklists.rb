FactoryBot.define do
  factory :handover_progress_checklist do
    trait :nps do
      association :offender, :nps
    end

    trait :crc do
      association :offender, :crc
    end

    trait :nps_complete do
      nps
      reviewed_oasys { true }
      contacted_com { true }
      attended_handover_meeting { true }
    end

    trait :crc_complete do
      crc
      contacted_com { true }
      sent_handover_report { true }
    end
  end
end
