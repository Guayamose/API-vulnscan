class Finding < ApplicationRecord
  belongs_to :scan
  validates :rule_id, :severity, :file_path, :line, :message, presence: true
  validates :line, numericality: { greater_than_or_equal_to: 1 }
  validates :severity, inclusion: { in: %w[LOW MEDIUM HIGH CRITICAL] }
end
