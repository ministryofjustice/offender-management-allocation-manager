FactoryBot.define do
  factory :parole_review_import do
    title { '13 - A jolly title' }
    prison_no { 'LEI' }
    sentence_type { 'Discretionary' }
    sentence_date { '1/1/20' }
    tariff_exp { '1/1/22' }
    review_type { 'zzzGPP - I' }
    snapshot_date { Time.zone.today }
    sequence(:row_number)
    import_id { '348734bv648b7648b56456' }
    single_day_snapshot { true }
    processed_on { nil }
  end
end

