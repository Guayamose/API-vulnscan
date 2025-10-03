class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def render_error(code, msg, status, details = {})
    render json: { error: code, message: msg, details: details }, status: status
  end
  def not_found = render_error('not_found', 'resource not found', :not_found)

  # ✅ PATCH
  def require_bearer!
    token = extract_access_token
    return render_error('invalid_token', 'missing/invalid bearer', :unauthorized) if token.blank?

    payload, = JWT.decode(token, ENV.fetch('JWT_SECRET'), true, { algorithm: 'HS256' })
    @current_user_id = payload['sub'] || payload['user_id']
    @current_org     = payload['org']
    # fallback: algunos tokens usan "role" en lugar de "scope"
    @current_scope   = payload['scope'] || payload['role']
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render_error('invalid_token', 'token invalid/expired', :unauthorized)
  end

  private

  # ✅ Nuevo helper: toma Authorization: Bearer ... o params[:token][:access]
  def extract_access_token
    # 1) Header Authorization (case-insensitive, tolerante a espacios)
    auth = request.authorization.to_s
    if auth =~ /\ABearer\s+(.+)\z/i
      return Regexp.last_match(1)
    end

    # 2) Rails params anidado: token[access]=<jwt>
    t = params[:token]
    if t.is_a?(ActionController::Parameters) || t.is_a?(Hash)
      v = t[:access] || t['access']
      return v if v.present?
    end

    nil
  end
end
