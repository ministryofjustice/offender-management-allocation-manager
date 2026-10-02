require 'rails_helper'

RSpec.describe SignificantChanges::HandoverDetector do
  include_context 'with a significant changes detector'

  let(:in_window) { changed_at.to_date + DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION }
  let(:out_of_window) { in_window + 1.day }
  let(:moved_out) { handover_version({ 'handover_date' => [in_window, out_of_window] }) }

  before do
    travel_to(changed_at)
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
  end

  it 'flags a date-only move from the upcoming window to outside it' do
    expect(detect(moved_out)).to have_attributes(
      type: :handover, label: 'Handover date', from_value: in_window, to_value: out_of_window, changed_at:
    )
  end

  it 'flags a move out when responsibility also changes' do
    version = handover_version({
      'responsibility' => [CalculatedHandoverDate::COMMUNITY_RESPONSIBLE, CalculatedHandoverDate::CUSTODY_ONLY],
      'handover_date' => [in_window, out_of_window]
    })

    expect(detect(version)).to have_attributes(type: :handover)
  end

  it 'flags moving out when a prison POM is recommended but a probation POM is allocated' do
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
    allow(review).to receive(:allocated_pom_position).and_return(RecommendationService::PROBATION_POM)

    expect(detect(moved_out)).to have_attributes(type: :handover)
  end

  it 'does not flag when the recommended POM type matches the allocated POM' do
    allow(review).to receive(:allocated_pom_position).and_return(RecommendationService::PROBATION_POM)

    expect(detect(moved_out)).to be_nil
  end

  it 'does not flag when the allocated POM type is unknown' do
    allow(review).to receive(:allocated_pom_position).and_return(nil)

    expect(detect(moved_out)).to be_nil
  end

  it 'does not flag when there is no current recommendation' do
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::NO_RECOMMENDATION)

    expect(detect(moved_out)).to be_nil
  end

  it 'does not flag a responsibility-only change' do
    version = handover_version({
      'responsibility' => [CalculatedHandoverDate::COMMUNITY_RESPONSIBLE, CalculatedHandoverDate::CUSTODY_ONLY]
    })

    expect(detect(version)).to be_nil
  end

  it 'does not flag a recalculation that stays within the window' do
    version = handover_version({ 'handover_date' => [in_window - 1.day, in_window] })

    expect(detect(version)).to be_nil
  end

  it 'does not flag a recalculation that was already outside the window' do
    version = handover_version({ 'handover_date' => [out_of_window, out_of_window + 1.day] })

    expect(detect(version)).to be_nil
  end

  it 'does not flag moving into the window' do
    version = handover_version({ 'handover_date' => [out_of_window, in_window] })

    expect(detect(version)).to be_nil
  end

  it 'does not flag when the previous handover date is unknown' do
    expect(detect(handover_version({ 'handover_date' => [nil, out_of_window] }))).to be_nil
  end

  it 'does not flag when the new handover date is unknown' do
    expect(detect(handover_version({ 'handover_date' => [in_window, nil] }))).to be_nil
  end

  it 'does not flag a move out that has since been reversed' do
    back_inside = handover_version({ 'handover_date' => [out_of_window, in_window] }, changed_at + 1.day)

    expect(detect(moved_out, back_inside)).to be_nil
  end

  it 'dates a renewed move out from the latest crossing' do
    far_outside = in_window + 3.months
    first = handover_version({ 'handover_date' => [in_window, far_outside] }, changed_at - 2.days)
    back_inside = handover_version({ 'handover_date' => [far_outside, in_window] }, changed_at - 1.day)
    latest = handover_version({ 'handover_date' => [in_window, far_outside + 1.day] })

    expect(detect(first, back_inside, latest)).to have_attributes(changed_at:)
  end

  it 'uses the window at the time of the recalculation, not today, for the previous date' do
    previously_outside = out_of_window + 1.day
    travel_to(changed_at + 3.days)
    version = handover_version({ 'handover_date' => [previously_outside, out_of_window + 3.months] })

    expect(detect(version)).to be_nil
  end

  it 'stops flagging when the new date enters the upcoming window' do
    travel_to(changed_at + 2.days)

    expect(detect(moved_out)).to be_nil
  end
end
