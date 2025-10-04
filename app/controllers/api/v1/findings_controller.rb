# app/controllers/api/v1/findings_controller.rb
module Api
  module V1
    class FindingsController < ApplicationController
      before_action :set_scan, only: [:create]

      # POST /api/v1/findings
      # Admite tanto payloads bulk como individuales.
      def create
        items = if params[:items].is_a?(Array)
                  params[:items]
                elsif params[:finding].present?
                  [params[:finding]]
                else
                  []
                end

        if items.empty?
          render json: { error: 'No findings provided' }, status: :unprocessable_content
          return
        end

        created = items.map do |item|
          Finding.create!(
            scan: @scan,
            rule_id: item[:rule_id],
            severity: normalize_severity(item[:severity]),
            file_path: item[:path] || item[:file_path],
            line: item[:line],
            message: item[:message],
            fingerprint_hint: item[:fingerprint] || item[:fingerprint_hint],
            engine: item[:engine],
            owasp: item[:owasp],
            cwe: item[:cwe],
            references: item[:references],
            title: item[:title],
            summary: item[:summary],
            recommendation: item[:recommendation],
            metadata: item[:metadata] || {}
          )
        end

        render json: { count: created.size, ids: created.map(&:id) }, status: :created
      rescue => e
        render json: { error: e.message }, status: :unprocessable_content
      end

      private

      # Busca o crea un Scan válido
      def set_scan
        raw_id = params[:scan_id].presence
        @scan = Scan.find_by(id: raw_id) if raw_id&.match?(/\A\d+\z/)

        # Si viene "undefined" o no existe, coge el último scan del usuario/org
        if @scan.nil?
          @scan = Scan.order(created_at: :desc).first
          Rails.logger.warn("[findings#create] scan_id undefined, fallback to last scan #{@scan&.id}")
        end
      end

      def normalize_severity(level)
        return nil unless level
        case level.to_s.downcase
        when 'info', 'information' then 'INFO'
        when 'low' then 'LOW'
        when 'medium' then 'MEDIUM'
        when 'high' then 'HIGH'
        when 'critical' then 'CRITICAL'
        else level.to_s.upcase
        end
      end
    end
  end
end
