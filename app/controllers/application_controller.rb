# app/controllers/api/v1/auth/tokens_controller.rb
class Api::V1::Auth::TokensController < ApplicationController
  # ... refresh y revoke como ya los tienes ...

  # GET /api/v1/auth/whoami
  # Acepta:
  #  - Authorization: Bearer <access>
  #  - token[access]=<jwt> (query/body), para compat
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
        user_id: sub,   # compat con clientes que miran user_id
        org:     org,
        role:    role,
        scope:   scope
      }
    rescue JWT::ExpiredSignature, JWT::DecodeError
      render_error('invalid_token', 'token invalid/expired', :unauthorized)
    end
  end
end
