class Rack::Attack
  throttle('req/ip', limit: 60, period: 1.minute) { |req| req.ip }
end
Rails.application.config.middleware.use Rack::Attack
