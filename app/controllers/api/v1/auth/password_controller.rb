# frozen_string_literal: true

class Api::V1::Auth::PasswordController < ApplicationController
  # POST /api/v1/auth/password_login
  def login
    # Normaliza y valida entrada
    u = login_params[:username].to_s.strip.downcase
    p = login_params[:password].to_s
    return invalid_credentials! if u.blank? || p.blank?

    # Búsqueda case-insensitive por email (usa índice LOWER(email) si puedes)
    user = User.find_by('LOWER(email) = ?', u)
    return invalid_credentials! unless user&.authenticate(p)

    # Emite tokens
    access  = JwtIssuer.issue_access(user)
    refresh = JwtIssuer.issue_refresh(user)

    # Evita cache de credenciales en proxies
    response.headers['Cache-Control'] = 'no-store'
    response.headers['Pragma']        = 'no-cache'

    render json: {
      access: access,
      refresh: refresh,
      expires_in: 900, # 15 min (debe alinear con exp del access)
      user: {
        sub:  user.id,
        org:  user.organization.slug,
        role: user.role
      }
    }
  end

  private

  def login_params
    # Permitimos solo lo necesario
    params.permit(:username, :password)
  end

  def invalid_credentials!
    render_error('invalid_credentials', 'Usuario o contraseña incorrectos', :unauthorized)
  end
end
