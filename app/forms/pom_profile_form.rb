# frozen_string_literal: true

class PomProfileForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  DESCRIPTIONS = %w[FT PT].freeze
  WORKING_PATTERNS = (1..9).map { |v| "0.#{v}" }.freeze

  attribute :status, :string
  attribute :description, :string
  attribute :working_pattern, :string

  validates :description, inclusion: DESCRIPTIONS
  validates :working_pattern, inclusion: { in: WORKING_PATTERNS }, if: :part_time?
  validates :status, inclusion: PomDetail.statuses.keys

  def part_time?
    description == 'PT'
  end

  def working_pattern_ratio
    part_time? ? working_pattern : '1.0'
  end
end
