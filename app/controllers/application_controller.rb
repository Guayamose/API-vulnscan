class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :force_json # ✅ asegura JSON en toda la API

  def render_error(code, msg, status, details = {})
    render json: { error: code, message: msg, details: details }, status: status
  end

  def not_found = render_error('not_found', 'resource not found', :not_found)

  # ✅ Valida Authorization: Bearer ... o token[access]
  def require_bearer!
    token = extract_access_token
    return render_error('invalid_token', 'missing/invalid bearer', :unauthorized) if token.blank?

    payload, = JWT.decode(token, ENV.fetch('JWT_SECRET'), true, { algorithm: 'HS256' })
    @current_user_id = payload['sub'] || payload['user_id']
    @current_org     = payload['org']
    # Compat: algunos tokens usan "role" en lugar de "scope" (y viceversa)
    @current_scope   = payload['scope'] || payload['role']
    @current_role    = payload['role']  || payload['scope']
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render_error('invalid_token', 'token invalid/expired', :unauthorized)
  end

  private

  # ✅ asegura que el request se procese como JSON
  def force_json
    request.format = :json
  end

  # ✅ Header Bearer o params[:token][:access]
  def extract_access_token
    auth = request.authorization.to_s
    if auth =~ /\ABearer\s+(.+)\z/i
      return Regexp.last_match(1)
    end

    t = params[:token]
    if t.is_a?(ActionController::Parameters) || t.is_a?(Hash)
      v = t[:access] || t['access']
      return v if v.present?
    end

    nil
  end
end
