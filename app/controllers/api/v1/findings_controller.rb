# app/controllers/api/v1/findings_controller.rb
module Api
  module V1
    class FindingsController < ApplicationController
      before_action :require_bearer!, only: :create

      def index
        scope = Finding.all
        scope = scope.where(scan_id: params[:scan_id]) if params[:scan_id].present?
        render json: scope
      end

      # POST /api/v1/findings
      # Payloads soportados:
      #  - { scan_id, items: [ { ... } ] }
      #  - { scan_id, finding: { ... } }
      def create
        items = if params[:items].is_a?(Array)
                  params[:items]
                elsif params[:finding].present?
                  [params[:finding]]
                else
                  []
                end
        return render_error('validation_error', 'No findings provided', :unprocessable_content) if items.empty?

        scan = resolve_scan_id(params, items)
        return render_error('validation_error', 'unknown scan_id', :unprocessable_content) unless scan

        created = []
        ActiveRecord::Base.transaction do
          items.each do |item|
            created << Finding.create!(
              scan: scan,
              rule_id: item[:rule_id] || item['rule_id'],
              severity: normalize_severity(item[:severity] || item['severity']),
              file_path: (item[:file_path] || item['file_path'] || item[:path] || item['path']),
              line: (item[:line] || item['line']),
              message: item[:message] || item['message'],
              fingerprint_hint: (item[:fingerprint] || item['fingerprint'] || item[:fingerprint_hint] || item['fingerprint_hint']),
              engine: item[:engine] || item['engine'],
              owasp: item[:owasp] || item['owasp'],
              cwe: item[:cwe] || item['cwe'],
              references: item[:references] || item['references'],
              title: item[:title] || item['title'],
              summary: item[:summary] || item['summary'],
              recommendation: item[:recommendation] || item['recommendation'],
              metadata: (item[:metadata] || item['metadata'] || {})
            )
          end
        end

        render json: { count: created.size, ids: created.map(&:id) }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render_error('validation_error', 'invalid finding payload', :unprocessable_content, e.record.errors.to_hash)
      rescue => e
        Rails.logger.error("[findings#create] #{e.class}: #{e.message}")
        render_error('server_error', 'unexpected error', :unprocessable_content)
      end

      private

      # Busca un scan usable a partir de:
      # 1) params[:scan_id]
      # 2) item[:scan_id] en el payload
      # 3) fallback: último scan del mismo org del token; si no hay, último global
      def resolve_scan_id(params_hash, items)
        raw_ids = []
        raw_ids << params_hash[:scan_id] << params_hash['scan_id']
        items.each { |it| raw_ids << it[:scan_id] << it['scan_id'] }

        candid = raw_ids.compact.map(&:to_s).reject { |v| v.blank? || v == 'undefined' }.first
        if candid&.match?(/\A\d+\z/)
          found = Scan.find_by(id: candid.to_i)
          return found if found
        end

        if defined?(@current_org) && @current_org.present?
          org_scan = Scan.where(org: @current_org).order(created_at: :desc).first
          return org_scan if org_scan
        end

        Scan.order(created_at: :desc).first
      end

      def normalize_severity(level)
        return nil unless level
        case level.to_s.downcase
        when 'info', 'information' then 'INFO'
        when 'low'                 then 'LOW'
        when 'medium'              then 'MEDIUM'
        when 'high'                then 'HIGH'
        when 'critical'            then 'CRITICAL'
        else level.to_s.upcase
        end
      end
    end
  end
end
