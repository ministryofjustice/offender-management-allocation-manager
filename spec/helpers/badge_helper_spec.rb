# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BadgeHelper, type: :helper do
  context 'when determinate' do
    let(:offender) { build(:hmpps_api_offender, sentence: build(:sentence_detail, :determinate)) }

    it 'is blue' do
      expect(helper.badge_colour(offender)).to eq 'blue'
    end

    it 'displays determinant' do
      expect(helper.badge_text(offender)).to eq 'Determinate'
    end
  end

  context 'when indeterminate' do
    let(:offender) { build(:hmpps_api_offender, sentence: build(:sentence_detail, :indeterminate)) }

    it 'is purple' do
      expect(helper.badge_colour(offender)).to eq 'purple'
    end

    it 'displays indeterminate' do
      expect(helper.badge_text(offender)).to eq 'Indeterminate'
    end
  end

  describe 'early allocation badges' do
    context 'when early allocations comes after the current sentence start date' do
      let(:offender) {
        build(:hmpps_api_offender,
              sentence: build(:sentence_detail, conditionalReleaseDate: nil)).tap { |offender|
          offender.load_case_information(case_info)
        }
      }

      xdescribe '#early_allocation_notes?' do
        context 'when its not been sent (its not within the early allocation window)' do
          let(:case_info) {
            create(:case_information,
                   early_allocations: [build(:early_allocation, :unsent)])
          }

          it 'displays EARLY ALLOCATION NOTES' do
            expect(helper.early_allocation_notes?(offender, case_info.early_allocations)).to eq true
          end
        end

        context 'when it has been declined by the community' do
          let(:case_info) {
            create(:case_information,
                   early_allocations: [build(:early_allocation, :discretionary_declined)])
          }

          it 'displays EARLY ALLOCATION NOTES' do
            expect(helper.early_allocation_notes?(offender, case_info.early_allocations)).to eq true
          end
        end
      end

      describe '#early_allocation_active?' do
        let(:offender) {
          build(:hmpps_api_offender,
                sentence: build(:sentence_detail, sentenceStartDate: Time.zone.today - 1.week)).tap { |offender|
            offender.load_case_information(case_info)
          }
        }

        let(:case_info) { create(:case_information, early_allocations: [early_allocation]) }

        context 'when it is awaiting review by NSD/LDU' do
          let(:early_allocation) { build(:early_allocation, :discretionary) }

          it 'displays badge text EARLY ALLOCATION ACTIVE' do
            expect(helper.early_allocation_active?(offender, case_info.early_allocations)).to eq true
          end
        end
      end

      describe '#early_allocation_approved?' do
        let(:offender) {
          build(:hmpps_api_offender,
                sentence: build(:sentence_detail, sentenceStartDate: Time.zone.today - 1.week)).tap { |offender|
            offender.load_case_information(case_info)
          }
        }

        let(:case_info) { create(:case_information, early_allocations: [early_allocation]) }

        context 'when it has been approved by NSD/LDU' do
          let(:early_allocation) { build(:early_allocation, :discretionary_accepted) }

          it 'displays badge text EARLY ALLOCATION APPROVED' do
            expect(helper.early_allocation_approved?(offender)).to eq true
          end
        end

        context 'when it has been approved by NSD/LDU but earlier than sentence start date' do
          let(:early_allocation) { build(:early_allocation, :discretionary_accepted, created_at: Time.zone.today - 2.weeks) }

          it 'doesnt displays badge text EARLY ALLOCATION APPROVED' do
            expect(helper).not_to be_early_allocation_approved(offender)
          end
        end

        context 'when it is automatic' do
          let(:early_allocation) { build(:early_allocation, :eligible) }

          it 'displays badge text EARLY ALLOCATION APPROVED' do
            expect(helper.early_allocation_approved?(offender)).to eq true
          end
        end
      end
    end
  end
end
