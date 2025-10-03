class Admin::DashboardController < Admin::BaseController
  def index
    @orgs_count     = Organization.count
    @users_count    = User.count
    @scans_count    = Scan.count
    @findings_count = Finding.count

    @recent_scans     = Scan.order(created_at: :desc).limit(10)
    @recent_findings  = Finding.order(created_at: :desc).limit(10)
  end
end
