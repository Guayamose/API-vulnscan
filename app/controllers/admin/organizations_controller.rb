class Admin::OrganizationsController < Admin::BaseController
  def index
    page, per = page_params
    scope = Organization.order(:name)
    scope = scope.where('name ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    @orgs = scope.limit(per).offset((page - 1) * per)
    @page, @per = page, per
  end

  def show
    @org = Organization.find(params[:id])
    page, per = page_params
    @users = @org.users.order(:email).limit(per).offset((page - 1) * per)
    @scans = Scan.where(org: @org.slug).order(created_at: :desc).limit(20)
  end
end
