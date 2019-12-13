# frozen_string_literal: true

class LocalDivisionalUnit < ApplicationRecord
  validates :code, :name, presence: true
  has_many :teams

  scope :nps, -> { where('code like ?', 'N%') }
end
