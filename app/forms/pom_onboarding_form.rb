# frozen_string_literal: true

class PomOnboardingForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :search_query, :string
  attribute :position, :string
  attribute :schedule_type, :string
  attribute :working_pattern, :integer

  POM_POSITIONS = [
    POSITION_PRISON_POM = 'PRO',
    POSITION_PROBATION_POM = 'PO',
  ].freeze

  SCHEDULE_TYPES = [
    FULL_TIME = 'FT',
    PART_TIME = 'PT',
  ].freeze

  # Search step
  validates :search_query, length: { minimum: 3 }, on: :search

  # Position step
  validates :position, inclusion: POM_POSITIONS, on: :position

  # Working pattern step
  validates :schedule_type, inclusion: SCHEDULE_TYPES, on: :working_pattern
  validates :working_pattern, numericality: { only_integer: true, in: 1..9 }, if: -> { part_time? }, on: :working_pattern

  def search_query=(val)
    super(val.try(:squish))
  end

  def part_time?
    schedule_type == PART_TIME
  end

  def working_pattern=(value)
    super(value) if part_time?
  end

  def working_pattern_ratio
    part_time? ? working_pattern / 10.0 : 1.0
  end

  def hours_per_week
    working_pattern_ratio * PomDetail::FULL_TIME_HOURS_PER_WEEK
  end
end
