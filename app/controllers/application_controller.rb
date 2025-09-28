class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def render_error(code, msg, status, details = {})
    render json: { error: code, message: msg, details: details }, status: status
  end
  def not_found = render_error('not_found', 'resource not found', :not_found)

  def require_bearer!
    auth = request.authorization
    return render_error('invalid_token', 'missing/invalid bearer', :unauthorized) unless auth&.start_with?('Bearer ')
    token = auth.split(' ', 2).last
    payload, = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
    @current_user_id = payload['sub']; @current_org = payload['org']; @current_scope = payload['scope']
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render_error('invalid_token', 'token invalid/expired', :unauthorized)
  end
end
