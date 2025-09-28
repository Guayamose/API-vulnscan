class Api::V1::Auth::PasswordController < ApplicationController
  def login
    user = User.find_by(email: params[:username].to_s.downcase)
    return render_error('invalid_credentials', 'Usuario o contraseña incorrectos', :unauthorized) unless user&.authenticate(params[:password])

    access  = JwtIssuer.issue_access(user)
    refresh = JwtIssuer.issue_refresh(user)
    render json: {
      access: access, refresh: refresh, expires_in: 900,
      user: { sub: user.id, org: user.organization.slug, role: user.role }
    }
  end
end
