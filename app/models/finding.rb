# app/models/finding.rb
class Finding < ApplicationRecord
  belongs_to :scan

  validates :rule_id, presence: true
  validates :severity, inclusion: { in: %w[INFO LOW MEDIUM HIGH CRITICAL], allow_nil: true }

  # jsonb en schema — no es obligatorio el serialize, pero no molesta
  serialize :owasp, JSON
  serialize :cwe, JSON
  serialize :references, JSON
  serialize :metadata, JSON
end
