class JwtIssuer
  SECRET = ENV.fetch('JWT_SECRET')

  def self.issue_access(user)
    payload = {
      sub: user.id,
      org: user.organization.slug,
      role: user.role,
      scope: 'ingest:write profile:read',
      exp: 15.minutes.from_now.to_i
    }
    JWT.encode(payload, SECRET, 'HS256')
  end

  def self.issue_refresh(user)
    jti = SecureRandom.uuid
    exp = 30.days.from_now
    RefreshToken.create!(user: user, jti: jti, expires_at: exp)
    JWT.encode({ sub: user.id, jti: jti, exp: exp.to_i }, SECRET, 'HS256')
  end

  def self.rotate_refresh!(token)
    payload, = JWT.decode(token, SECRET, true, { algorithm: 'HS256' })
    rt = RefreshToken.active.find_by!(user_id: payload['sub'], jti: payload['jti'])
    rt.update!(revoked_at: Time.current)
    user = rt.user
    { access: issue_access(user), refresh: issue_refresh(user) }
  rescue JWT::DecodeError, JWT::ExpiredSignature, ActiveRecord::RecordNotFound
    nil
  end
end
