class Admin::UsersController < Admin::BaseController
  def index
    page, per = page_params
    scope = User.includes(:organization).order(created_at: :desc)
    scope = scope.where('email ILIKE ?', "%#{params[:q]}%") if params[:q].present?
    @users = scope.limit(per).offset((page - 1) * per)
    @page, @per = page, per
  end

  def show
    @user = User.find(params[:id])
    page, per = page_params
    @scans = Scan.where(user_ref: @user.id).order(created_at: :desc).limit(per).offset((page - 1) * per)
  end
end
