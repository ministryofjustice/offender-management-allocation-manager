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

  # Safety threshold: if the API returns fewer than this percentage of the
  # existing LDU count, abort the import to avoid mass deletion caused by
  # an upstream API issue (empty response, partial data, misconfiguration)
  MINIMUM_RETENTION_PERCENTAGE = 90

  attr_reader :dry_run

  def initialize(dry_run: true)
    @dry_run = dry_run
  end

  def call
    existing_ldu_codes = LocalDeliveryUnit.pluck(:code)
    mailboxes = HmppsApi::MailboxRegisterApi.get_local_delivery_units

    log("Number of LDUs in database: #{existing_ldu_codes.size}")
    log("Retrieved #{mailboxes.size} mailboxes from register. Processing...")

    if Rails.env.production? && existing_ldu_codes.any? && below_safety_threshold?(mailboxes.size, existing_ldu_codes.size)
      log("ABORTING: API returned #{mailboxes.size} mailboxes but we have #{existing_ldu_codes.size} LDUs locally. " \
          "This looks like a partial or empty response (threshold: #{MINIMUM_RETENTION_PERCENTAGE}%).")
      return
    end

    destroys_count = 0
    creates_count = 0
    updates_count = 0
    failure_count = 0
    failed_codes = []

    mailboxes.each do |mailbox|
      code = mailbox['unitCode']
      name = mailbox['name']
      uuid = mailbox['id']

      # Look up by UUID first, then fall back to code. This handles the case
      # where an LDU was deleted from Mailbox Register and re-added with the
      # same code but a new UUID, as we want to update the existing record (and
      # preserve its associations) rather than trying to delete-and-recreate.
      ldu = (LocalDeliveryUnit.find_by(mailbox_register_id: uuid) ||
             LocalDeliveryUnit.find_by(code: code) ||
             LocalDeliveryUnit.new).tap do |record|
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

      unless dry_run
        LocalDeliveryUnit.where(code: existing_ldu_codes).find_each do |ldu|
          ldu.destroy!
          destroys_count += 1
        rescue ActiveRecord::DeleteRestrictionError => e
          log("Failed to remove LDU: #{ldu.code} - #{e.message}")
          failure_count += 1
          failed_codes << ldu.code
        end
      end
    else
      log('No LDUs need to be removed')
    end

    log('--' * 25)
    log("Finished processing LDUs: #{creates_count} new, #{updates_count} updates, #{destroys_count} destroys")
    log("Failures (#{failure_count}): #{failed_codes.join(', ')}") if failure_count.positive?
    log("Number of LDUs in database: #{LocalDeliveryUnit.count}")
  end

private

  def below_safety_threshold?(remote_count, local_count)
    return false if local_count.zero?

    (remote_count.to_f / local_count * 100) < MINIMUM_RETENTION_PERCENTAGE
  end

  def log(msg)
    logger.info("[#{self.class}] #{log_prefix}#{msg}")
  end

  def log_prefix
    @log_prefix ||= dry_run ? '(dry_run) ' : ''
  end

  def logger
    @logger ||= Rails.env.test? ? Rails.logger : Logger.new($stdout)
  end
end
