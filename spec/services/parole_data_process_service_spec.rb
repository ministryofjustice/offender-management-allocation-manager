require 'rails_helper'

RSpec.describe ParoleDataProcessService do
  subject(:results) { described_class.process }

  let(:snapshot_date) { Date.new(2025, 1, 1) }

  let(:offender1) { create(:offender, nomis_offender_id: 'A1111AA') }
  let(:offender2) { create(:offender, nomis_offender_id: 'B2222BB') }
  let(:offender3) { create(:offender, nomis_offender_id: 'C3333CC') }

  describe 'for the initial import, single_day_snapshot false' do
    before do
      create(:parole_review_import, nomis_id: offender1.nomis_offender_id,
                                    review_type: 'GPP ISP OnPost Tariff',
                                    review_date: '1/1/22',
                                    review_id: '123456',
                                    review_milestone_date_id: '12345678',
                                    review_status: 'Active - Referred',
                                    curr_target_date: '1/1/22',
                                    ms13_target_date: '1/1/21',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Applicable',
                                    snapshot_date: snapshot_date,
                                    single_day_snapshot: false)

      create(:parole_review_import, nomis_id: offender1.nomis_offender_id,
                                    review_type: 'GPP MH Accelerated Review Other',
                                    review_date: '1/1/19',
                                    review_id: '098765',
                                    review_milestone_date_id: '98765432',
                                    review_status: 'Active',
                                    curr_target_date: '1/1/19',
                                    ms13_target_date: '1/1/19',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Applicable',
                                    snapshot_date: snapshot_date,
                                    single_day_snapshot: false)

      create(:parole_review_import, nomis_id: offender2.nomis_offender_id,
                                    review_type: 'GPP SOPC Parole Review',
                                    review_date: '1/1/19',
                                    review_id: '024680',
                                    review_milestone_date_id: '02468024',
                                    review_status: 'Cancelled',
                                    curr_target_date: '1/1/19',
                                    ms13_target_date: '1/1/19',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Specified',
                                    snapshot_date: snapshot_date,
                                    single_day_snapshot: false)

      create(:parole_review_import, nomis_id: offender2.nomis_offender_id,
                                    review_date: '1/2/19',
                                    review_id: '024681',
                                    review_milestone_date_id: '02468024',
                                    review_status: 'Cancelled',
                                    curr_target_date: '1/1/19',
                                    ms13_target_date: '1/1/19',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Specified',
                                    snapshot_date: snapshot_date,
                                    single_day_snapshot: false)
    end

    let(:parole_review1) { ParoleReview.find_by(review_id: '123456', nomis_offender_id: offender1.nomis_offender_id) }
    let(:parole_review2) { ParoleReview.find_by(review_id: '098765', nomis_offender_id: offender1.nomis_offender_id) }
    let(:parole_review3) { ParoleReview.find_by(review_id: '024680', nomis_offender_id: offender2.nomis_offender_id) }
    let(:parole_review4) { ParoleReview.find_by(review_id: '024681', nomis_offender_id: offender2.nomis_offender_id) }

    it 'there are 2 parole reviews for each offender' do
      results
      expect(ParoleReview.where(nomis_offender_id: offender1.nomis_offender_id).count).to eq(2)
      expect(ParoleReview.where(nomis_offender_id: offender2.nomis_offender_id).count).to eq(2)
    end

    it 'hearing outcome recieved on should be nil' do
      results
      expect(parole_review1.hearing_outcome_received_on).to eq(nil)
      expect(parole_review2.hearing_outcome_received_on).to eq(nil)
      expect(parole_review3.hearing_outcome_received_on).to eq(nil)
      expect(parole_review4.hearing_outcome_received_on).to eq(nil)
    end

    it 'has expected reported counts' do
      expect(results[:total_count]).to eq(4)
      expect(results[:processed_count]).to eq(4)
      expect(results[:parole_reviews_created_count]).to eq(4)
      expect(results[:parole_reviews_updated_count]).to eq(0)
    end
  end

  describe 'for ongoing initial imports, single_day_snapshot true' do
    before do
      create(:parole_review_import, nomis_id: offender1.nomis_offender_id,
                                    review_type: 'GPP ISP OnPost Tariff',
                                    review_date: '01-01-2022',
                                    review_id: '123456',
                                    review_milestone_date_id: '12345678',
                                    review_status: 'Active - Referred',
                                    curr_target_date: '01-01-2022',
                                    ms13_target_date: '01-01-2021',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Some kinda result',
                                    single_day_snapshot: true,
                                    snapshot_date: snapshot_date)

      create(:parole_review_import, nomis_id: offender2.nomis_offender_id,
                                    review_type: 'GPP MH Accelerated Review Other',
                                    review_date: '01-01-2019',
                                    review_id: '098765',
                                    review_milestone_date_id: '98765432',
                                    review_status: 'Active',
                                    curr_target_date: '01-01-2019',
                                    ms13_target_date: '01-01-2019',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Applicable',
                                    single_day_snapshot: true,
                                    snapshot_date: snapshot_date)

      create(:parole_review_import, nomis_id: offender3.nomis_offender_id,
                                    review_type: 'GPP SOPC Parole Review',
                                    review_date: '01-01-2019',
                                    review_id: '024680',
                                    review_milestone_date_id: '02468024',
                                    review_status: 'Cancelled',
                                    curr_target_date: '01-01-2019',
                                    ms13_target_date: '01-01-2019',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Specified',
                                    single_day_snapshot: true,
                                    snapshot_date: snapshot_date)
    end

    let(:parole_review1) { ParoleReview.find_by(review_id: '123456', nomis_offender_id: offender1.nomis_offender_id) }
    let(:parole_review2) { ParoleReview.find_by(review_id: '098765', nomis_offender_id: offender2.nomis_offender_id) }
    let(:parole_review3) { ParoleReview.find_by(review_id: '024680', nomis_offender_id: offender3.nomis_offender_id) }

    describe 'on first run' do
      it 'creates 3 records' do
        results

        expect(parole_review1.active?).to eq(true)
        expect(parole_review1.hearing_outcome_as_current).to eq('Some kinda result')
        expect(parole_review1.target_hearing_date).to eq(Date.new(2022, 1, 1))
        expect(parole_review1.custody_report_due).to eq(Date.new(2021, 1, 1))
        expect(parole_review1.review_type).to eq('GPP ISP OnPost Tariff')
        expect(parole_review1.hearing_outcome_received_on).to eq(snapshot_date)

        expect(parole_review2.active?).to eq(true)
        expect(parole_review2.hearing_outcome_as_historic).to eq('Refused')
        expect(parole_review2.target_hearing_date).to eq(Date.new(2019, 1, 1))
        expect(parole_review2.custody_report_due).to eq(Date.new(2019, 1, 1))
        expect(parole_review2.review_type).to eq('GPP MH Accelerated Review Other')
        expect(parole_review2.hearing_outcome_received_on).to eq(nil)

        expect(parole_review3.active?).to eq(false)
        expect(parole_review3.hearing_outcome_as_historic).to eq('Refused')
        expect(parole_review3.target_hearing_date).to eq(Date.new(2019, 1, 1))
        expect(parole_review3.custody_report_due).to eq(Date.new(2019, 1, 1))
        expect(parole_review3.review_type).to eq('GPP SOPC Parole Review')
        expect(parole_review3.hearing_outcome_received_on).to eq(nil)
      end

      it 'has expected reported counts' do
        expect(results[:total_count]).to eq(3)
        expect(results[:processed_count]).to eq(3)
        expect(results[:parole_reviews_created_count]).to eq(3)
        expect(results[:parole_reviews_updated_count]).to eq(0)
      end
    end

    describe "on the next day's run" do
      before do
        described_class.process # Yesterday's run

        # Today, some more imports are in. They duplicate yesterday's but the first has changed
        create(:parole_review_import, nomis_id: offender1.nomis_offender_id,
                                      review_type: 'GPP ISP OnPost Tariff',
                                      review_date: '01-01-2022',
                                      review_id: '123456',
                                      review_milestone_date_id: '12345678',
                                      review_status: 'Inactive', # Was 'Active - Referred' in yesterdays import
                                      curr_target_date: '01-01-2022',
                                      ms13_target_date: '01-01-2021',
                                      ms13_completion_date: '01-01-2021', # Was 'NULL' in yesterday's import
                                      final_result: 'Stay In Closed [*]', # Was different in yesterday's import
                                      snapshot_date: snapshot_date + 1.day)

        # Duplicate of yesterday
        create(:parole_review_import, nomis_id: offender2.nomis_offender_id,
                                      review_type: 'GPP MH Accelerated Review Other',
                                      review_date: '01-01-2019',
                                      review_id: '098765',
                                      review_milestone_date_id: '98765432',
                                      review_status: 'Active',
                                      curr_target_date: '01-01-2019',
                                      ms13_target_date: '01-01-2019',
                                      ms13_completion_date: 'NULL',
                                      final_result: 'Not Applicable',
                                      snapshot_date: snapshot_date + 1.day)

        # Duplicate of yesterday
        create(:parole_review_import, nomis_id: offender3.nomis_offender_id,
                                      review_type: 'GPP SOPC Parole Review',
                                      review_date: '01-01-2019',
                                      review_id: '024680',
                                      review_milestone_date_id: '02468024',
                                      review_status: 'Cancelled',
                                      curr_target_date: '01-01-2019',
                                      ms13_target_date: '01-01-2019',
                                      ms13_completion_date: 'NULL',
                                      final_result: 'Not Specified',
                                      snapshot_date: snapshot_date + 1.day)
      end

      it 'updates the changed record and leaves any others the same' do
        results # Today's run

        expect(parole_review1.active?).to eq(false)
        expect(parole_review1.hearing_outcome_as_current).to eq('Stay in closed')
        expect(parole_review1.hearing_outcome_received_on).to eq(snapshot_date) # Already got it yesterday

        expect(parole_review2.active?).to eq(true)
        expect(parole_review2.hearing_outcome_as_historic).to eq('Refused')
        expect(parole_review2.hearing_outcome_received_on).to eq(nil)

        expect(parole_review3.active?).to eq(false)
        expect(parole_review3.hearing_outcome_as_historic).to eq('Refused')
        expect(parole_review3.hearing_outcome_received_on).to eq(nil)
      end

      it 'has expected reported counts' do
        expect(results[:total_count]).to eq(3)
        expect(results[:processed_count]).to eq(3)
        expect(results[:parole_reviews_created_count]).to eq(0)
        expect(results[:parole_reviews_updated_count]).to eq(1)
      end
    end
  end

  context 'when an exception is thrown during record processing' do
    before do
      create(:parole_review_import, nomis_id: offender1.nomis_offender_id,
                                    review_date: '01-01-2022',
                                    review_id: '123456',
                                    review_milestone_date_id: '12345678',
                                    review_status: 'Active - Referred',
                                    curr_target_date: '01-01-2022',
                                    ms13_target_date: '01-01-2021',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Applicable',
                                    snapshot_date: snapshot_date)

      allow(ParoleReview).to receive(:find_or_initialize_by).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)
    end

    it 'logs the error message to the console' do
      results

      expect(Rails.logger).to have_received(:error).once
    end

    it 'catches exception' do
      expect { results }.not_to raise_error
    end

    it 'has expected reported counts' do
      expect(results[:total_count]).to eq(1)
      expect(results[:processed_count]).to eq(1)
      expect(results[:parole_reviews_created_count]).to eq(0)
      expect(results[:parole_reviews_updated_count]).to eq(0)
      expect(results[:other_error_count]).to eq(1)
    end
  end

  describe 'target hearing date' do
    it 'is populated with the review_date value' do
      create(:offender, nomis_offender_id: 'A1111AA')
      create(:parole_review_import, nomis_id: 'A1111AA',
                                    review_type: 'GPP ISP OnPost Tariff',
                                    review_date: '10/10/21',
                                    review_id: '123456',
                                    review_milestone_date_id: '12345678',
                                    review_status: 'Active - Referred',
                                    curr_target_date: '2/1/2022',
                                    ms13_target_date: '2/1/2021',
                                    ms13_completion_date: 'NULL',
                                    final_result: 'Not Applicable',
                                    snapshot_date: snapshot_date,
                                    single_day_snapshot: false)

      described_class.process

      parole_review = ParoleReview.find_by(nomis_offender_id: 'A1111AA')
      expect(parole_review.target_hearing_date).to eq(Date.parse('10/10/2021'))
    end
  end
end
