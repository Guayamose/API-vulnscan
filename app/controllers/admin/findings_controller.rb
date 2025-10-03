class Admin::FindingsController < Admin::BaseController
  def index
    page, per = page_params
    scope = Finding.order(created_at: :desc)
    scope = scope.where(scan_id: params[:scan_id]) if params[:scan_id].present?
    scope = scope.where(severity: params[:severity]) if params[:severity].present?
    scope = scope.where('file_path ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    @findings = scope.limit(per).offset((page - 1) * per)
    @page, @per = page, per
  end

  def show
    @finding = Finding.find(params[:id])
    @scan = Scan.find_by(id: @finding.scan_id)
  end
end
