# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::Offender do
  subject {
    build(:hmpps_api_offender, sentence: sentence)
  }

  let(:prison) { build(:prison) }

  describe '#inside_omic_policy?' do
    let(:over_18) { (Time.zone.today - 18.years).to_s }
    let(:immigration_detainee) { 'DET' }

    context 'when it meets the requirements' do
      context 'when all requirements are present: immigration case, over 18, sentence, criminal sentence' do
        let(:offender) { build(:hmpps_api_offender,  imprisonmentStatus: immigration_detainee, dateOfBirth: over_18, legalStatus: 'IMMIGRATION_DETAINEE', sentence: attributes_for(:sentence_detail, sentenceStartDate: '2019-02-05')) }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end

      context 'when they have no sentence' do
        let(:offender) {
          build(:hmpps_api_offender,
                dateOfBirth: over_18, legalStatus: 'IMMIGRATION_DETAINEE',
                        sentence: attributes_for(:sentence_detail, :unsentenced, imprisonmentStatus: immigration_detainee))
        }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end

      context 'when they have no immigration case' do
        let(:offender) { build(:hmpps_api_offender, dateOfBirth: over_18, legalStatus: 'SENTENCED', sentence: attributes_for(:sentence_detail, sentenceStartDate: '2019-02-05')) }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end
    end

    context 'when the requirements arent met:' do
      context 'when they are under 18' do
        let(:under_18) { (Time.zone.today - 17.years).to_s }
        let(:offender) {
          build(:hmpps_api_offender,
                sentence: attributes_for(:sentence_detail, imprisonmentStatus: immigration_detainee),
                        dateOfBirth: under_18, legalStatus: 'IMMIGRATION_DETAINEE')
        }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end

      context 'when have no immigration case and no sentence' do
        let(:offender) { build(:hmpps_api_offender, dateOfBirth: over_18, sentence: attributes_for(:sentence_detail, :unsentenced)) }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end

      context 'when they do not have a criminal sentence (and are not an immigration case)' do
        let(:offender) {
          build(:hmpps_api_offender, dateOfBirth: over_18, legalStatus: 'CIVIL_PRISONER',
                               sentence: attributes_for(:sentence_detail, :civil_sentence, sentenceStartDate: '2019-02-05'))
        }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end
    end
  end

  describe '#earliest_release_date' do
    context 'with blank sentence detail' do
      let(:sentence) { attributes_for(:sentence_detail, :blank) }

      it 'responds with no earliest release date' do
        expect(subject.earliest_release_date).to be_nil
      end
    end

    context 'when main dates are missing' do
      let(:today_plus1) { Time.zone.today + 1.day }

      context 'with just the sentence expiry date' do
        let(:sentence) { attributes_for(:sentence_detail, :blank) }

        before do
          # Set the sentence expiry date – this one is a bit odd because we don't actually populate it from the API
          subject.sentence.sentence_expiry_date = today_plus1
        end

        it 'uses the SED' do
          expect(subject.earliest_release_date).to eq(today_plus1)
        end
      end

      context 'with many dates' do
        let(:sentence) {
          attributes_for(:sentence_detail, :blank,
                         licenceExpiryDate: licence_expiry_date,
                         postRecallReleaseDate: post_recall_release_date,
                         actualParoleDate: actual_parole_date)
        }

        before do
          subject.sentence.sentence_expiry_date = sentence_expiry_date
        end

        context 'with future dates' do
          let(:licence_expiry_date) { Time.zone.today + 2.days }
          let(:sentence_expiry_date) { Time.zone.today + 3.days }
          let(:post_recall_release_date) { Time.zone.today + 4.days }
          let(:actual_parole_date) { Time.zone.today + 5.days }

          context 'with licence date nearest' do
            let(:licence_expiry_date) { today_plus1 }

            it 'uses the licence expiry date' do
              expect(subject.earliest_release_date).to eq(licence_expiry_date)
            end
          end

          context 'with post_recall_release_date nearest' do
            let(:post_recall_release_date) { today_plus1 }

            it 'uses the post_recall_release_date' do
              expect(subject.earliest_release_date).to eq(post_recall_release_date)
            end
          end

          context 'with actual_parole_date nearest' do
            let(:actual_parole_date) { today_plus1 }

            it 'uses the actual_parole_date' do
              expect(subject.earliest_release_date).to eq(actual_parole_date)
            end
          end
        end

        context 'with all dates in the past' do
          let(:sentence_expiry_date) { Time.zone.today - 2.days }
          let(:licence_expiry_date) { Time.zone.today - 3.days }
          let(:post_recall_release_date) { Time.zone.today - 4.days }
          let(:actual_parole_date) { Time.zone.today - 5.days }

          it 'uses the closest to today' do
            expect(subject.earliest_release_date).to eq(sentence_expiry_date)
          end
        end
      end
    end

    context 'with sentence detail with dates' do
      let(:sentence) {
        attributes_for(:sentence_detail,
                       sentenceStartDate: Date.new(2005, 2, 3),
                       paroleEligibilityDate: parole_eligibility_date,
                       conditionalReleaseDate: conditional_release_date)
      }

      context 'when comprised of dates in the past and the future' do
        let(:parole_eligibility_date) { Date.new(2009, 1, 1) }
        let(:automatic_release_date) { Time.zone.today }
        let(:conditional_release_date) { Time.zone.today + 3.days }

        it 'will display the earliest of the dates in the future' do
          expect(subject.earliest_release_date).
              to eq(conditional_release_date)
        end
      end

      context 'when comprised solely of dates in the past' do
        let(:parole_eligibility_date) { Date.new(2009, 1, 1) }
        let(:automatic_release_date) { Date.new(2009, 1, 11) }
        let(:conditional_release_date) { Date.new(2009, 1, 21) }

        it 'will display the most recent of the dates in the past' do
          expect(subject.earliest_release_date).
              to eq(conditional_release_date)
        end
      end
    end
  end

  describe '#sentenced?' do
    context 'with sentence detail with a release date' do
      let(:sentence) {
        attributes_for(:sentence_detail,
                       sentenceStartDate: Date.new(2005, 2, 3),
                       releaseDate: Time.zone.today)
      }

      it 'marks the offender as sentenced' do
        expect(subject.sentenced?).to be true
      end
    end

    context 'with blank sentence detail' do
      let(:sentence) { attributes_for(:sentence_detail, :blank) }

      it 'marks the offender as not sentenced' do
        expect(subject.sentenced?).to be false
      end
    end
  end

  describe '#over_18?' do
    subject {
      build(:hmpps_api_offender, dateOfBirth: dob.to_s)
    }

    context 'with a date of birth 18 years ago' do
      let(:dob) { 18.years.ago }

      it 'returns true' do
        expect(subject.over_18?).to eq(true)
      end
    end

    context 'with a date of birth just under 18 years ago' do
      let(:dob) { 18.years.ago + 1.day }

      it 'returns false' do
        expect(subject.over_18?).to eq(false)
      end
    end

    context 'with an 18th birthday in a past month' do
      let(:dob) { '5 Jan 2001'.to_date }

      it 'returns true' do
        Timecop.travel('19 Feb 2019') do
          expect(subject.over_18?).to eq(true)
        end
      end
    end
  end

  describe '#recalled' do
    context 'when recall flag set' do
      let(:sentence) { attributes_for(:sentence_detail, recall: true) }

      it 'is true' do
        expect(subject.recalled?).to eq(true)
      end
    end

    context 'when recall flag unset' do
      let(:sentence) { attributes_for(:sentence_detail, recall: false) }

      it 'is false' do
        expect(subject.recalled?).to eq(false)
      end
    end
  end

  describe '#needs_early_allocation_notify?' do
    let(:release_date) { Time.zone.today + 15.months }
    let(:offender) { build(:mpc_offender, prison_record: api_offender, offender: case_info.offender, prison: prison) }

    context 'with active early allocations outside window' do
      let(:case_info) {
        create(:case_information, offender: build(:offender,
                                                  early_allocations: [build(:early_allocation, :pre_window)]))
      }

      let(:api_offender) {
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, conditionalReleaseDate: release_date))
      }

      it 'is true' do
        expect(offender.needs_early_allocation_notify?).to eq(true)
      end
    end

    context 'when another allocation has been started' do
      let(:case_info) {
        create(:case_information, offender: build(:offender,
                                                  early_allocations: [build(:early_allocation, :pre_window),
                                                                      build(:early_allocation)]))
      }

      let(:api_offender) {
        build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, conditionalReleaseDate: release_date))
      }

      it 'is false' do
        expect(offender.needs_early_allocation_notify?).to eq(false)
      end
    end
  end
end
