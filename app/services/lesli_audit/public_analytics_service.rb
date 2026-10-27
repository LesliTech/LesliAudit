module LesliAudit
    class PublicAnalyticsService < Lesli::ApplicationLesliService
        LIMIT = 10

        def summary
            page_views, visits = rollups.pick(
                Arel.sql("COALESCE(SUM(page_views), 0)"),
                Arel.sql("COALESCE(SUM(visits), 0)")
            )

            {
                page_views: page_views.to_i,
                visits: visits.to_i,
                resources: rollups.group(:resource_type, :resource_id).count.length,
                sources: rollups.group(:provider, :provider_key).count.length
            }
        end

        def traffic
            rollups
                .group(:date)
                .order(:date)
                .pluck(
                    :date,
                    Arel.sql("SUM(page_views)"),
                    Arel.sql("SUM(visits)")
                )
                .map do |date, page_views, visits|
                    {
                        "xaxiskey" => date,
                        "yaxiskey" => page_views.to_i,
                        "visits" => visits.to_i
                    }
                end
        end

        def resources
            rollups
                .group(:resource_type, :resource_id)
                .order(Arel.sql("SUM(page_views) DESC"))
                .limit(LIMIT)
                .pluck(
                    :resource_type,
                    :resource_id,
                    Arel.sql("SUM(page_views)"),
                    Arel.sql("SUM(visits)")
                )
                .map do |resource_type, resource_id, page_views, visits|
                    {
                        "resource" => "#{resource_type} ##{resource_id}",
                        "page_views" => page_views.to_i,
                        "visits" => visits.to_i
                    }
                end
        end

        def breakdown(dimension)
            dimension = dimension.to_s
            return [] unless account && VisitorBreakdown::DIMENSIONS.include?(dimension)

            records = account.visitor_breakdowns
                .where(visitor_rollup_id: rollups.select(:id), dimension:)
                .group(:value)
                .order(Arel.sql("SUM(page_views) DESC"))
                .limit(LIMIT)
                .pluck(
                    :value,
                    Arel.sql("SUM(page_views)"),
                    Arel.sql("SUM(visits)")
                )

            total = records.sum { |_value, page_views, _visits| page_views.to_i }
            records.map do |value, page_views, visits|
                page_views = page_views.to_i
                {
                    value:,
                    page_views:,
                    visits: visits.to_i,
                    percentage: total.zero? ? 0 : ((page_views.to_f / total) * 100).round
                }
            end
        end

        private

        def account
            @account ||= current_user&.account&.audit
        end

        def rollups
            @rollups ||= begin
                relation = account ? account.visitor_rollups : VisitorRollup.none
                relation = apply_time_filter(relation)
                relation = relation.where(resource_type: query[:resource_type].to_s.strip) if query[:resource_type].present?
                relation = relation.where(resource_id: resource_id_filter) if resource_id_filter
                relation
            end
        end

        def resource_id_filter
            return @resource_id_filter if defined?(@resource_id_filter)

            @resource_id_filter = Integer(query[:resource_id], exception: false)
            @resource_id_filter = nil unless @resource_id_filter&.positive?
            @resource_id_filter
        end

        def apply_time_filter(relation)
            start_date = case query[:bytime].presence || "month"
            when "day" then Date.current
            when "week" then 6.days.ago.to_date
            when "month" then 29.days.ago.to_date
            when "sixmonth" then 6.months.ago.to_date
            when "year" then 1.year.ago.to_date
            end

            start_date ? relation.where(date: start_date..) : relation
        end
    end
end
