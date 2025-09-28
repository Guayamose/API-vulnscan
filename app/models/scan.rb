class Scan < ApplicationRecord
  has_many :findings, dependent: :destroy
  SCAN_TYPES = %w[workspace realtime ci].freeze
  STATUSES   = %w[queued processing completed failed].freeze
  validates :idempotency_key, :project_slug, :scan_type, :started_at, :finished_at,
           :findings_ingested, :deduped, :status, presence: true
  validates :scan_type, inclusion: { in: SCAN_TYPES }
  validates :status, inclusion: { in: STATUSES }
  validate  :finished_after_start
  def finished_after_start
    errors.add(:finished_at, 'must be >= started_at') if finished_at && started_at && finished_at < started_at
  end
end
