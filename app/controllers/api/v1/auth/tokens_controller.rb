class Api::V1::Auth::TokensController < ApplicationController
  # POST /api/v1/auth/refresh
  def refresh
    token = params[:refresh].to_s.presence || params.dig(:token, :refresh).to_s
    tokens = JwtIssuer.rotate_refresh!(token)
    return render_error('invalid_token', 'refresh invalid/expired', :unauthorized) unless tokens

    render json: tokens.merge(expires_in: 900)
  end

  # POST /api/v1/auth/revoke
  def revoke
    token = params[:refresh].to_s.presence || params.dig(:token, :refresh).to_s
    if token.blank?
      head :no_content and return
    end

    begin
      payload, = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
      RefreshToken.where(user_id: payload['sub'], jti: payload['jti']).update_all(revoked_at: Time.current)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      # idempotente: igualmente 204
    end

    head :no_content
  end

  # GET /api/v1/auth/whoami
  # Compat:
  # - Authorization: Bearer <access>
  # - token[access]=<jwt>
  def whoami
    require_bearer! and return if performed?

    render json: {
      # claves compatibles con el cliente VS Code
      sub:      @current_user_id,
      user_id:  @current_user_id, # por compat con clientes que lean user_id
      org:      @current_org,
      role:     @current_role,
      scope:    @current_scope
    }
  end
end
