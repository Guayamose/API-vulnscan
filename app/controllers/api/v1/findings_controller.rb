class Api::V1::FindingsController < ApplicationController
  before_action :require_bearer!, only: :create

  def index
    f = Finding.all
    f = f.where(scan_id: params[:scan_id]) if params[:scan_id]
    render json: f
  end

  def create
    scan = Scan.find_by(id: params[:scan_id])
    return render_error('validation_error','unknown scan_id', :unprocessable_entity) unless scan
    finding = scan.findings.new(finding_params)
    if finding.save
      render json: finding, status: :created
    else
      render_error('validation_error','invalid finding payload', :unprocessable_entity, finding.errors.to_hash)
    end
  end

  private
  def finding_params
    params.permit(:rule_id, :severity, :file_path, :line, :message, :fingerprint_hint)
  end
end
