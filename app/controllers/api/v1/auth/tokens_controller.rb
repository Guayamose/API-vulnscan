class Api::V1::Auth::TokensController < ApplicationController
  def refresh
    tokens = JwtIssuer.rotate_refresh!(params[:refresh].to_s)
    return render_error('invalid_token', 'refresh invalid/expired', :unauthorized) unless tokens
    render json: tokens.merge(expires_in: 900)
  end

  def revoke
    token = params[:refresh].to_s
    payload, = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
    RefreshToken.where(user_id: payload['sub'], jti: payload['jti']).update_all(revoked_at: Time.current)
    head :no_content
  rescue JWT::DecodeError, JWT::ExpiredSignature
    head :no_content
  end

  def whoami
    require_bearer! and return if performed?
    render json: { user_id: @current_user_id, org: @current_org, scope: @current_scope }
  end
end
