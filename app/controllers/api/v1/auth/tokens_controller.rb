# app/controllers/api/v1/auth/tokens_controller.rb
class Api::V1::Auth::TokensController < ApplicationController
  # POST /api/v1/auth/refresh
  def refresh
    token  = params[:refresh].to_s.presence || params.dig(:token, :refresh).to_s
    tokens = JwtIssuer.rotate_refresh!(token)
    return render_error('invalid_token', 'refresh invalid/expired', :unauthorized) unless tokens
    render json: tokens.merge(expires_in: 900)
  end

  # POST /api/v1/auth/revoke
  def revoke
    token = params[:refresh].to_s.presence || params.dig(:token, :refresh).to_s
    if token.present?
      begin
        payload, = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
        RefreshToken.where(user_id: payload['sub'], jti: payload['jti']).update_all(revoked_at: Time.current)
      rescue JWT::DecodeError, JWT::ExpiredSignature
        # idempotente: devolvemos 204 igualmente
      end
    end
    head :no_content
  end

  # GET /api/v1/auth/whoami
  # Acepta Authorization: Bearer <access> y/o token[access]=<jwt> (query/body)
  def whoami
    token = extract_access_token
    return render_error('invalid_token', 'missing/invalid bearer', :unauthorized) if token.blank?

    begin
      payload, = JWT.decode(token, ENV.fetch('JWT_SECRET'), true, { algorithm: 'HS256' })

      sub   = payload['sub'] || payload['user_id']
      org   = payload['org']
      role  = payload['role']  || payload['scope']
      scope = payload['scope'] || payload['role']

      render json: {
        sub:     sub,
        user_id: sub,  # compat
        org:     org,
        role:    role,
        scope:   scope
      }
    rescue JWT::ExpiredSignature, JWT::DecodeError
      render_error('invalid_token', 'token invalid/expired', :unauthorized)
    end
  end
end
