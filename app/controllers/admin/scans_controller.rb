class Admin::ScansController < Admin::BaseController
  def index
    page, per = page_params
    scope = Scan.order(created_at: :desc)
    scope = scope.where(project_slug: params[:project_slug]) if params[:project_slug].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(idempotency_key: params[:idempotency_key]) if params[:idempotency_key].present?
    @scans = scope.limit(per).offset((page - 1) * per)
    @page, @per = page, per
  end

  def show
    @scan = Scan.find(params[:id])
    page, per = page_params
    @findings = Finding.where(scan_id: @scan.id).order(Arel.sql("CASE severity
      WHEN 'CRITICAL' THEN 4 WHEN 'HIGH' THEN 3 WHEN 'MEDIUM' THEN 2 WHEN 'LOW' THEN 1 ELSE 0 END DESC"))
      .limit(per).offset((page - 1) * per)
  end
end
