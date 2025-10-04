class Finding < ApplicationRecord
  SEVERITIES = %w[LOW MEDIUM HIGH CRITICAL].freeze

  belongs_to :scan

  # Normaliza antes de validar
  before_validation :normalize_fields

  # Validaciones mínimas para que no vuelva el 422 por tonterías
  validates :rule_id, :severity, :file_path, :line, :message, presence: true
  validates :line, numericality: { greater_than_or_equal_to: 1 }
  validates :severity, inclusion: { in: SEVERITIES }

  private

  def normalize_fields
    # Upcase y mapeos suaves
    sev = severity.to_s.strip.upcase
    sev = 'LOW' if sev == 'INFO' || sev == 'INFORMATIONAL'
    self.severity = sev if sev.present?

    # Asegura tipos JSONB compatibles (arrays u objeto)
    self.owasp       = Array.wrap(owasp).compact.presence
    self.cwe         = Array.wrap(cwe).compact.presence
    self.references  = Array.wrap(references).compact.presence
    self.metadata    = metadata.is_a?(Hash) ? metadata : {}

    # Limpieza de strings
    self.rule_id          = rule_id.to_s.strip if rule_id
    self.file_path        = file_path.to_s.strip if file_path
    self.message          = message.to_s.strip if message
    self.title            = title.to_s.strip if title
    self.summary          = summary.to_s.strip if summary
    self.recommendation   = recommendation.to_s.strip if recommendation
    self.engine           = engine.to_s.strip if engine
    self.fingerprint_hint = fingerprint_hint.to_s.strip if fingerprint_hint
  end
end
