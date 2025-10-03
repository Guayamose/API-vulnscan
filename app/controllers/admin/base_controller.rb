class Admin::BaseController < ActionController::Base
  layout 'admin'

  # No usamos formularios mutantes; evitamos CSRF por simplicidad
  protect_from_forgery with: :null_session

  before_action :http_basic_auth

  private

  def http_basic_auth
    user = ENV['ADMIN_USER'] || 'oryon'
    pass = ENV['ADMIN_PASS'] || 'oryon'
    authenticate_or_request_with_http_basic('Oryon Admin') do |u, p|
      ActiveSupport::SecurityUtils.secure_compare(u, user) &&
        ActiveSupport::SecurityUtils.secure_compare(p, pass)
    end
  end

  # paginación sencilla via ?page= & ?per=
  def page_params(default: 1, per: 50, max: 200)
    p  = params.fetch(:page, default).to_i
    pp = [params.fetch(:per,  per).to_i, max].min
    [p < 1 ? 1 : p, pp < 1 ? 1 : pp]
  end
end
