require 'rails_helper'

RSpec.describe "prisoners/show", type: :view do
  describe 'early allocation badges' do
    let(:prison) { build(:prison) }
    let(:page) { Nokogiri::HTML(rendered) }
    let(:early_allocation_badge) { page.css('#early-allocation-badge').first }
    let(:offender) { build(:offender, sentence: sentence).tap { |offender| offender.load_case_information(case_info) } }

    before do
      assign(:prison, prison)
      assign(:prisoner, offender)
      assign(:tasks, [])
      assign(:keyworker, build(:keyworker))
      assign(:case_info, case_info)
      render
    end

    context 'with early allocation' do
      let(:case_info) { create(:case_information, early_allocations: [early_allocation]) }

      context 'when unsent' do
        let(:early_allocation) { build(:early_allocation, :unsent) }
        let(:sentence) { build(:sentence_detail, :outside_early_allocation_window) }

        it 'displays a badge text EARLY ALLOCATION NOTES' do
          expect(early_allocation_badge.attributes['class'].value).to include 'moj-badge--blue'
          expect(early_allocation_badge.text).to include 'EARLY ALLOCATION NOTES'
        end
      end

      context 'when submitted' do
        # default sentence is inside EA 18 month window
        let(:sentence) { build(:sentence_detail) }

        context 'when rejected' do
          let(:early_allocation) { build(:early_allocation, :discretionary_declined) }

          it 'displays badge text EARLY ALLOCATION NOTES' do
            expect(early_allocation_badge.attributes['class'].value).to include 'moj-badge--blue'
            expect(early_allocation_badge.text).to include 'EARLY ALLOCATION NOTES'
          end
        end

        context 'when it is awaiting review by NSD/LDU' do
          let(:early_allocation) { build(:early_allocation, :discretionary) }

          it 'displays badge text EARLY ALLOCATION ACTIVE' do
            expect(early_allocation_badge.attributes['class'].value).to include 'moj-badge--blue'
            expect(early_allocation_badge.text).to include 'EARLY ALLOCATION ACTIVE'
          end
        end

        context 'when it has been approved by NSD/LDU' do
          let(:early_allocation) { build(:early_allocation, :discretionary_accepted) }

          it 'displays badge text EARLY ALLOCATION APPROVED' do
            expect(early_allocation_badge.attributes['class'].value).to include 'moj-badge--blue'
            expect(early_allocation_badge.text).to eq 'EARLY ALLOCATION APPROVED'
          end
        end

        context 'when it is automatic' do
          let(:early_allocation) { build(:early_allocation, :eligible) }

          it 'displays badge text EARLY ALLOCATION APPROVED' do
            expect(early_allocation_badge.attributes['class'].value).to include 'moj-badge--blue'
            expect(early_allocation_badge.text).to include 'EARLY ALLOCATION APPROVED'
          end
        end
      end
    end

    context 'without an early allocation' do
      let(:case_info) { build(:case_information) }
      let(:sentence) { build(:sentence_detail) }

      it 'has no badge' do
        expect(early_allocation_badge).to be_nil
      end
    end
  end
end
