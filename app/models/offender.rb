# frozen_string_literal: true

class Offender < ApplicationRecord
  attr_reader :current_parole_record, :previous_parole_records

  # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters> (all uppercase)
  validates :nomis_offender_id, format: { with: /\A[A-Z][0-9]{4}[A-Z]{2}\z/ }

  has_one :case_information, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :early_allocations,
           -> { order(created_at: :asc) },
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_many :email_histories,
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_one :responsibility,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  # This is quite a loose relationship. It exists so that CaseInformation
  # deletes cascade and tidy up associated CalculatedHandoverDate records.
  # Ideally CalculatedHandoverDate would belong to a higher-level
  # Offender model rather than nDelius Case Information
  has_one :calculated_handover_date,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  has_many :parole_records, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_one :calculated_early_allocation_status, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :victim_liaison_officers, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  def most_recent_parole_record
    parole_records.max_by(&:custody_report_due)
  end

  def build_parole_record_sections
    @current_parole_record = nil
    @previous_parole_records = []

    parole_records.sort_by(&:custody_report_due).reverse_each do |record|
      if record.no_hearing_outcome?
        if record.active?
          @current_parole_record = record
        else
          @previous_parole_records << record
        end
      elsif record.hearing_outcome_received && record.hearing_outcome_received > Time.zone.today - 14.days
        @current_parole_record = record
      else
        @previous_parole_records << record
      end
    end
  end
end
