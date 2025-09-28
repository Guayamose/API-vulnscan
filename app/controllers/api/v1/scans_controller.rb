require 'digest'
class Api::V1::ScansController < ApplicationController
  before_action :require_bearer!, only: :create

  def index
    if params[:idempotency_key]
      scan = Scan.find_by!(idempotency_key: params[:idempotency_key])
      return render json: scan
    end
    scans = Scan.order(created_at: :desc)
    scans = scans.where(project_slug: params[:project_slug]) if params[:project_slug]
    scans = scans.where(status: params[:status]) if params[:status]
    render json: scans
  end

  def show
    render json: Scan.find(params[:id])
  end

  def create
    idem = request.headers['Idempotency-Key'] || params[:idempotency_key]
    return render_error('validation_error','Idempotency-Key required', :unprocessable_entity) unless idem

    body_hash = Digest::SHA256.hexdigest(request.raw_post.to_s)
    if (existing = Scan.find_by(idempotency_key: idem))
      return render json: success(existing), status: :created if existing.body_hash == body_hash
      return render_error('idempotency_conflict','same Idempotency-Key different body', :conflict)
    end

    scan = Scan.new(scan_params.merge(idempotency_key: idem, body_hash: body_hash))
    if scan.save
      render json: success(scan), status: :created
    else
      render_error('validation_error','invalid scan payload', :unprocessable_entity, scan.errors.to_hash)
    end
  end

  private
  def scan_params
    params.permit(:org, :user_ref, :project_slug, :scan_type, :commit_sha,
                  :started_at, :finished_at, :findings_ingested, :deduped, :status)
  end
  def success(s)
    { scan_id: s.id.to_s, findings_ingested: s.findings_ingested, deduped: s.deduped,
      status: s.status, meta: { project_slug: s.project_slug, scan_type: s.scan_type } }
  end
end
