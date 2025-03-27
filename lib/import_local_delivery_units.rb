# frozen_string_literal: true

class ImportLocalDeliveryUnits
  # If running this import in development, these LDUs will not be deleted,
  # even if they are not found in Mailbox Register DB, as otherwise
  # we might run into problems with referenced seed data (`db/seeds.rb`)
  LOCAL_SEED_CODES = %w[
    WELDU
    ENLDU
    OTHERLDU
  ].freeze

  attr_reader :dry_run

  def initialize(dry_run: true)
    @dry_run = dry_run
  end

  def call
    existing_ldu_codes = LocalDeliveryUnit.pluck(:code)
    mailboxes = HmppsApi::MailboxRegisterApi.get_local_delivery_units

    log("Number of LDUs in database: #{existing_ldu_codes.size}")
    log("Retrieved #{mailboxes.size} mailboxes from register. Processing...")

    destroys_count = 0
    creates_count = 0
    updates_count = 0
    failure_count = 0
    failed_codes = []

    mailboxes.each do |mailbox|
      code = mailbox['unitCode']
      name = mailbox['name']
      uuid = mailbox['id']

      ldu = LocalDeliveryUnit
              .by_code_or_mailbox_register_id(code, uuid)
              .first_or_initialize.tap do |record|
        record.code = code
        record.mailbox_register_id = uuid
        record.name = mailbox['name'].presence || mailbox['emailAddress']
        record.email_address = mailbox['emailAddress']
        record.country = mailbox['country']
        record.enabled = record.enabled.nil? || record.enabled
        record.created_at = mailbox['createdAt']
        record.updated_at = mailbox['updatedAt']
      end

      existing_ldu_codes.delete(code)

      next unless ldu.new_record? || ldu.changes_to_save.any?

      if ldu.new_record?
        log("Creating LDU: #{code} (#{name})")
        creates_count += 1
      elsif ldu.changes_to_save.any?
        log("Updating LDU: #{code} (#{name}) -> #{ldu.changes_to_save}")
        updates_count += 1

        # Track changes in code, otherwise it "looks" like the old LDU was deleted
        # and a new one (with the new code) was created, but this is misleading,
        # as the LDU record remains the same (same ID), is the code that changes.
        # This only affects logging, not the actual data.
        existing_ldu_codes.delete(ldu.changed_attributes['code']) if ldu.code_changed?
      end

      begin
        ldu.save!(touch: false) unless dry_run
      rescue ActiveRecord::ActiveRecordError => e
        log("Failed to save LDU: #{code} (#{name}) - #{e.message}")
        failure_count += 1
        failed_codes << code
      end
    end

    if Rails.env.development?
      log("(!) Running in dev mode. Local seeds will not be deleted: #{LOCAL_SEED_CODES.join(', ')}")
      existing_ldu_codes -= LOCAL_SEED_CODES
    end

    if existing_ldu_codes.any?
      log("LDUs to be removed (#{existing_ldu_codes.size}): #{existing_ldu_codes.join(', ')}")
      destroys_count = LocalDeliveryUnit.where(code: existing_ldu_codes).destroy_all.size unless dry_run
    else
      log('No LDUs need to be removed')
    end

    log('--' * 25)
    log("Finished processing LDUs: #{creates_count} new, #{updates_count} updates, #{destroys_count} destroys")
    log("Failures (#{failure_count}): #{failed_codes.join(', ')}") if failure_count.positive?
    log("Number of LDUs in database: #{LocalDeliveryUnit.count}")
  end

private

  def log(msg)
    logger.info("[#{self.class}] #{log_prefix}#{msg}")
  end

  def log_prefix
    @log_prefix ||= dry_run ? '(dry_run) ' : ''
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
