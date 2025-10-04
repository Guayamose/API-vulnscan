class Api::V1::FindingsController < ApplicationController
  before_action :require_bearer!, only: :create

  # GET /api/v1/findings?scan_id=...
  def index
    scope = Finding.all
    scope = scope.where(scan_id: params[:scan_id]) if params[:scan_id].present?
    render json: scope.order(id: :asc)
  end

  # POST /api/v1/findings
  # Acepta:
  #  - objeto único en root o bajo { finding: {...} }
  #  - lote bajo { items: [ {...}, {...} ] }
  # Requiere scan_id (query param o en body). Rechaza "undefined".
  def create
    scan = resolve_scan!
    return if performed?

    payload = request.request_parameters.presence || params.to_unsafe_h

    # Lote
    if payload.is_a?(Hash) && payload['items'].is_a?(Array)
      items = payload['items']
      created = []
      errors  = []

      ActiveRecord::Base.transaction do
        items.each_with_index do |raw, idx|
          attrs   = normalize_finding_payload(raw)
          finding = scan.findings.new(attrs)
          if finding.save
            created << { index: idx, id: finding.id }
          else
            errors << { index: idx, errors: finding.errors.to_hash }
          end
        end

        raise ActiveRecord::Rollback if errors.any?
      end

      if errors.any?
        return render_error('validation_error',
                            'some items are invalid',
                            :unprocessable_entity,
                            { errors: errors })
      end

      return render json: { created: created }, status: :created
    end

    # Único
    raw     = payload['finding'] || payload
    attrs   = normalize_finding_payload(raw)
    finding = scan.findings.new(attrs)

    if finding.save
      render json: finding, status: :created
    else
      render_error('validation_error', 'invalid finding payload', :unprocessable_entity, finding.errors.to_hash)
    end
  end

  private

  # 1) saca scan_id de query o del body (si viniera ahí) y valida
  def resolve_scan!
    sid = params[:scan_id].presence ||
          dig_string(params, 'finding', 'scan_id') ||
          dig_string(params, 'scan_id')

    if sid.blank? || sid.to_s == 'undefined'
      render_error('validation_error', 'unknown scan_id', :unprocessable_entity)
      return nil
    end

    scan = Scan.find_by(id: sid)
    unless scan
      render_error('validation_error', 'unknown scan_id', :unprocessable_entity)
      return nil
    end
    scan
  end

  # 2) normaliza keys del payload real de la extensión a nuestros campos
  #    (path|file -> file_path, severity upcase, owasp/cwe arrays, etc.)
  def normalize_finding_payload(raw)
    h = to_hash(raw)

    {
      rule_id:           first_present(h, %w[rule_id rule id]),
      severity:          normalize_severity(first_present(h, %w[severity level sev])),
      file_path:         first_present(h, %w[file_path path file]),
      line:              (h['line'] || h['lineno'] || h['start_line']).to_i.nonzero? || 1,
      message:           h['message'] || h['msg'] || h['description'],

      title:             h['title'],
      summary:           h['summary'],
      recommendation:    h['recommendation'] || h['fix'] || h['remediation'],
      engine:            h['engine'],
      fingerprint_hint:  h['fingerprint_hint'] || h['fingerprint'],

      owasp:             arrayish(h['owasp']),
      cwe:               arrayish(h['cwe']),
      references:        arrayish(h['references'] || h['refs']),
      metadata:          h['metadata'].is_a?(Hash) ? h['metadata'] : {}
    }.compact
  end

  # ---- helpers de normalización ----

  def to_hash(obj)
    case obj
    when ActionController::Parameters then obj.to_unsafe_h
    when Hash then obj
    else {}
    end
  end

  def first_present(h, keys)
    keys.map { |k| h[k] || h[k.to_sym] }.find { |v| v.present? }
  end

  def arrayish(v)
    return nil if v.nil?
    v.is_a?(Array) ? v : [v].compact
  end

  def normalize_severity(v)
    s = v.to_s.strip.upcase
    return 'LOW' if s == 'INFO' || s == 'INFORMATIONAL'
    return s if Finding::SEVERITIES.include?(s)
    s.presence || 'LOW'
  end

  # lectura segura de params anidados (string keys)
  def dig_string(h, *ks)
    node = h
    ks.each do |k|
      node = node.is_a?(ActionController::Parameters) ? node[k] : (node.is_a?(Hash) ? node[k] : nil)
      return nil if node.nil?
    end
    node
  end
end
