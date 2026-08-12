# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportLocalDeliveryUnits do
  subject(:import) { described_class.new(dry_run:) }

  let(:dry_run) { false }

  def build_mailbox(code:, uuid: SecureRandom.uuid, name: Faker::Address.county, email: Faker::Internet.email)
    {
      'id' => uuid,
      'unitCode' => code,
      'name' => name,
      'emailAddress' => email,
      'country' => 'England',
      'createdAt' => '2025-01-01T00:00:00Z',
      'updatedAt' => '2025-06-01T00:00:00Z',
    }
  end

  before do
    allow(HmppsApi::MailboxRegisterApi).to receive(:get_local_delivery_units).and_return(mailboxes)
  end

  describe 'creating new LDUs' do
    let(:mailboxes) { [build_mailbox(code: 'NEWLDU', name: 'New Unit', email: 'new@example.com')] }

    it 'creates an LDU that does not exist locally' do
      expect { import.call }.to change(LocalDeliveryUnit, :count).by(1)

      ldu = LocalDeliveryUnit.find_by(code: 'NEWLDU')
      expect(ldu).to have_attributes(name: 'New Unit', email_address: 'new@example.com')
    end
  end

  describe 'updating existing LDUs' do
    let!(:existing) { create(:local_delivery_unit, code: 'EXIST1', name: 'Old Name', email_address: 'old@example.com', mailbox_register_id: uuid) }
    let(:uuid) { SecureRandom.uuid }
    let(:mailboxes) { [build_mailbox(code: 'EXIST1', uuid: uuid, name: 'New Name', email: 'new@example.com')] }

    it 'updates the existing LDU attributes' do
      expect { import.call }.not_to change(LocalDeliveryUnit, :count)

      existing.reload
      expect(existing).to have_attributes(name: 'New Name', email_address: 'new@example.com')
    end
  end

  describe 'LDU re-added with new UUID but same code' do
    let!(:existing) { create(:local_delivery_unit, code: 'READD1', name: 'Original', email_address: 'orig@example.com', mailbox_register_id: 'old-uuid') }
    let(:new_uuid) { SecureRandom.uuid }
    let(:mailboxes) { [build_mailbox(code: 'READD1', uuid: new_uuid, name: 'Updated', email: 'updated@example.com')] }

    it 'updates the existing record with the new UUID rather than creating a duplicate' do
      expect { import.call }.not_to change(LocalDeliveryUnit, :count)

      existing.reload
      expect(existing).to have_attributes(
        mailbox_register_id: new_uuid,
        name: 'Updated',
        email_address: 'updated@example.com'
      )
    end

    it 'does not queue the existing record for deletion' do
      import.call
      expect(LocalDeliveryUnit.find_by(code: 'READD1')).to be_present
    end
  end

  describe 'deleting LDUs no longer in Mailbox Register' do
    let!(:orphan) { create(:local_delivery_unit, code: 'ORPHAN1', mailbox_register_id: 'orphan-uuid') }
    let!(:kept_ldus) { create_list(:local_delivery_unit, 3) }
    let(:mailboxes) do
      kept_ldus.map { |ldu| build_mailbox(code: ldu.code, uuid: ldu.mailbox_register_id || SecureRandom.uuid) }
    end

    context 'when the LDU has no associated case_information' do
      it 'destroys the orphaned LDU' do
        expect { import.call }.to change(LocalDeliveryUnit, :count).by(-1)
        expect(LocalDeliveryUnit.find_by(code: 'ORPHAN1')).to be_nil
      end
    end

    context 'when the LDU has associated case_information' do
      before do
        create(:case_information, local_delivery_unit: orphan)
      end

      it 'does not destroy the LDU' do
        expect { import.call }.not_to change(LocalDeliveryUnit, :count)
        expect(LocalDeliveryUnit.find_by(code: 'ORPHAN1')).to be_present
      end
    end
  end

  describe 'safety threshold' do
    let!(:existing_ldus) { create_list(:local_delivery_unit, 10) }

    before { allow(Rails.env).to receive(:production?).and_return(true) }

    context 'when the API returns fewer than 90% of local LDUs' do
      let(:mailboxes) { [build_mailbox(code: 'ONLY1')] }

      it 'aborts without making any changes' do
        expect { import.call }.not_to change(LocalDeliveryUnit, :count)
      end
    end

    context 'when the API returns at least 90% of local LDUs' do
      let(:mailboxes) do
        existing_ldus.map { |ldu| build_mailbox(code: ldu.code, uuid: ldu.mailbox_register_id || SecureRandom.uuid) }
      end

      it 'proceeds with the import' do
        import.call
        expect(LocalDeliveryUnit.count).to eq(10)
      end
    end
  end

  describe 'dry run mode' do
    let(:dry_run) { true }
    let(:mailboxes) { [build_mailbox(code: 'DRYRUN1', name: 'Dry Run', email: 'dry@example.com')] }

    it 'does not persist any changes' do
      expect { import.call }.not_to change(LocalDeliveryUnit, :count)
    end
  end
end
