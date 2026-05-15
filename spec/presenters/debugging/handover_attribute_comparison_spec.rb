require 'rails_helper'

module Debugging
  describe HandoverAttributeComparison do
    let(:current_item) do
      instance_double(
        CalculatedHandoverDate::History::Item,
        offender_attributes: {
          'mappa_level' => 2,
          'recalled?' => true,
          'earliest_release_for_handover' => { 'name' => 'TED', 'date' => '2026-06-01' },
          'test_same_value' => 'same',
          'ldu_email_address' => nil,
          'team_name' => nil
        }
      )
    end

    let(:previous_item) do
      instance_double(
        CalculatedHandoverDate::History::Item,
        offender_attributes: {
          'mappa_level' => 1,
          'recalled?' => false,
          'earliest_release_for_handover' => { 'name' => 'TED', 'date' => '2026-05-01' },
          'test_same_value' => 'same',
          'ldu_email_address' => 'pom@example.com',
          'team_name' => nil
        }
      )
    end

    describe '#rows' do
      it 'builds comparable before and after rows for each archived field' do
        rows = described_class.new(current_item, previous_item).rows

        expect(rows).to include(
          {
            label: 'Mappa level',
            before: 1,
            after: 2,
            changed: true
          },
          {
            label: 'Recalled?',
            before: false,
            after: true,
            changed: true
          },
          {
            label: 'Earliest release for handover',
            before: { 'name' => 'TED', 'date' => '2026-05-01' },
            after: { 'name' => 'TED', 'date' => '2026-06-01' },
            changed: true
          },
          {
            label: 'Test same value',
            before: 'same',
            after: 'same',
            changed: false
          },
          {
            label: 'Ldu email address',
            before: 'pom@example.com',
            after: '(unset)',
            changed: true
          },
          {
            label: 'Team name',
            before: '—',
            after: '—',
            changed: false
          }
        )
      end

      it 'shows that the oldest snapshot has no earlier value' do
        rows = described_class.new(current_item, nil).rows

        expect(rows).to include(
          {
            label: 'Mappa level',
            before: 'No earlier value',
            after: 2,
            changed: true
          },
          {
            label: 'Ldu email address',
            before: 'No earlier value',
            after: '—',
            changed: false
          },
          {
            label: 'Team name',
            before: 'No earlier value',
            after: '—',
            changed: false
          }
        )
      end

      it 'shows not recorded only when a key was absent from the earlier snapshot' do
        rows = described_class.new(
          instance_double(CalculatedHandoverDate::History::Item, offender_attributes: { 'target_hearing_date' => Date.new(2026, 6, 1) }),
          instance_double(CalculatedHandoverDate::History::Item, offender_attributes: {})
        ).rows

        expect(rows).to include(
          {
            label: 'Target hearing date',
            before: 'Not recorded',
            after: Date.new(2026, 6, 1),
            changed: true
          }
        )
      end
    end
  end
end
