# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::OffenderSummary do
  subject {
    build(:offender_summary)
  }

  describe '#inside_omic_policy?' do
    let(:over_18) { (Time.zone.today - 18.years).to_s }
    let(:immigration_detainee) { 'DET' }

    context 'when it meets the requirements' do
      context 'when all requirements are present: immigration case, over 18, sentence, criminal sentence' do
        let(:offender) { build(:offender,  imprisonmentStatus: immigration_detainee, dateOfBirth: over_18, convictedStatus: 'Convicted', sentence: build(:sentence_detail, sentenceStartDate: '2019-02-05')) }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end

      context 'when they have no sentence' do
        let(:offender) {
          build(:offender,
                dateOfBirth: over_18, convictedStatus: 'Convicted',
                        sentence: build(:sentence_detail, :unsentenced, imprisonmentStatus: immigration_detainee))
        }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end

      context 'when they have no immigration case' do
        let(:offender) { build(:offender, dateOfBirth: over_18, convictedStatus: 'Convicted', sentence: build(:sentence_detail, sentenceStartDate: '2019-02-05')) }

        it 'is in omic policy' do
          expect(offender.inside_omic_policy?).to eq(true)
        end
      end
    end

    context 'when the requirements arent met:' do
      context 'when they are under 18' do
        let(:under_18) { (Time.zone.today - 17.years).to_s }
        let(:offender) {
          build(:offender,
                sentence: build(:sentence_detail, imprisonmentStatus: immigration_detainee),
                        dateOfBirth: under_18, convictedStatus: 'Convicted')
        }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end

      context 'when have no immigration case and no sentence' do
        let(:offender) { build(:offender, dateOfBirth: over_18, convictedStatus: 'Convicted', sentence: build(:sentence_detail, :unsentenced)) }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end

      context 'when they do not have a criminal sentence (and are not an immigration case)' do
        let(:offender) {
          build(:offender, dateOfBirth: over_18, convictedStatus: 'Convicted',
                               sentence: build(:sentence_detail, :civil_sentence, sentenceStartDate: '2019-02-05'))
        }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end

      context 'when they are not convicted?' do
        let(:offender) {
          build(:offender,  dateOfBirth: over_18, convictedStatus: false,
                               sentence: build(:sentence_detail, imprisonmentStatus: immigration_detainee, sentenceStartDate: '2019-02-05'))
        }

        it 'is not in omic policy' do
          expect(offender.inside_omic_policy?).to eq(false)
        end
      end
    end
  end

  describe '#earliest_release_date' do
    context 'with blank sentence detail' do
      before { subject.sentence = build(:sentence_detail, :blank) }

      it 'responds with no earliest release date' do
        expect(subject.earliest_release_date).to be_nil
      end
    end

    context 'when main dates are missing' do
      let(:today_plus1) { Time.zone.today + 1.day }

      context 'with just the sentence expiry date' do
        before do
          subject.sentence = build(:sentence_detail, :blank).tap { |s| s.sentence_expiry_date = today_plus1 }
        end

        it 'uses the SED' do
          expect(subject.earliest_release_date).to eq(today_plus1)
        end
      end

      context 'with many dates' do
        before do
          subject.sentence = build(:sentence_detail,
                                   :blank,
                                   licenceExpiryDate: licence_expiry_date,
                                   postRecallReleaseDate: post_recall_release_date,
                                   actualParoleDate: actual_parole_date).tap { |detail|
            detail.sentence_expiry_date = sentence_expiry_date
          }
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
      before do
        subject.sentence = build(:sentence_detail,
                                 sentenceStartDate: Date.new(2005, 2, 3),
                                 paroleEligibilityDate: parole_eligibility_date,
                                 conditionalReleaseDate: conditional_release_date)
      end

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

  describe '#category_label' do
    context 'with a category code' do
      let(:offender) { build(:offender, convictedStatus: 'Convicted', sentence: build(:sentence_detail, :unsentenced)) }

      before do
        stub_auth_token
        stub_category_label
      end

      it "can return the men's category description" do
        subject.category_code = 'A'
        expect(subject.category_label).to eq 'Cat A'
      end

      it "can return the women's category description" do
        subject.category_code = 'T'
        expect(subject.category_label).to eq 'Fem Open'
      end
    end
  end

  describe '#sentenced?' do
    context 'with sentence detail with a release date' do
      before do
        subject.sentence = build(:sentence_detail,
                                 sentenceStartDate: Date.new(2005, 2, 3),
                                 releaseDate: Time.zone.today)
      end

      it 'marks the offender as sentenced' do
        expect(subject.sentenced?).to be true
      end
    end

    context 'with blank sentence detail' do
      before { subject.sentence = build(:sentence_detail, :blank) }

      it 'marks the offender as not sentenced' do
        expect(subject.sentenced?).to be false
      end
    end
  end

  describe '#over_18?' do
    context 'with a date of birth 50 years ago' do
      before { subject.date_of_birth = 18.years.ago }

      it 'returns true' do
        expect(subject.over_18?).to eq(true)
      end
    end

    context 'with a date of birth just under 50 years ago' do
      before { subject.date_of_birth = 18.years.ago + 1.day }

      it 'returns false' do
        expect(subject.over_18?).to eq(false)
      end
    end

    context 'with an 18th birthday in a past month' do
      before { subject.date_of_birth = '5 Jan 2001'.to_date }

      it 'returns true' do
        Timecop.travel('19 Feb 2019') do
          expect(subject.over_18?).to eq(true)
        end
      end
    end
  end

  describe '#recalled' do
    context 'when recall flag set' do
      let(:offender) { build(:offender, sentence: build(:sentence_detail, recall: true)) }

      it 'is true' do
        expect(offender.recalled?).to eq(true)
      end
    end

    context 'when recall flag unset' do
      let(:offender) { build(:offender, recall: false) }

      it 'is false' do
        expect(offender.recalled?).to eq(false)
      end
    end
  end
end
