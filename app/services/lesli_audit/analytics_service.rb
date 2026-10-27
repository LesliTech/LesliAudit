=begin

Lesli

Copyright (c) 2023, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails SaaS development platform.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

module LesliAudit
    class AnalyticsService < Lesli::ApplicationLesliService
        CACHE_TTL = 1.hour
        CACHE_VERSION = 1
        LIMIT = 15

        PLATFORM_ICONS = {
            /chrome os|cros/i      => "chrome-fill",
            /ios|ipad|iphone|mac/i => "apple-fill",
            /windows/i             => "windows-fill",
            /ubuntu/i              => "ubuntu-fill",
            /debian|fedora|linux/i => "computer-fill",
            /android/i             => "android-fill"
        }.freeze

        BROWSER_ICONS = {
            /chrome|chromium/i        => "chrome-fill",
            /firefox/i                => "firefox-fill",
            /safari/i                 => "safari-fill",
            /edge/i                   => "edge-fill",
            /opera|opr/i              => "opera-fill",
            /internet explorer|msie/i => "ie-fill",
            /brave/i                  => "brave-fill"
        }.freeze

        DEVICE_ICONS = {
            "desktop"    => "mac-line",
            "tablet"     => "tablet-line",
            "smartphone" => "smartphone-line",
            "unknown"    => "file-unknow-line"
        }.freeze

        PERIODS = %w[day week month sixmonth year].freeze

        # Cache the complete dashboard as one unit. This keeps the policy in one
        # place and avoids six independent cache entries with different ages.
        def dashboard
            return build_dashboard unless cache_enabled?

            cache_store.fetch(cache_key, expires_in: CACHE_TTL) do
                build_dashboard
            end
        end

        private

        def summary
            controllers, total_requests = filtered_requests.pick(
                Arel.sql("COUNT(DISTINCT request_controller)"),
                Arel.sql("SUM(request_count)")
            )

            {
                controllers: controllers.to_i,
                requests: total_requests.to_i
            }
        end

        def request_trend
            date_group = daily_date_group

            filtered_requests
                .group(Arel.sql(date_group))
                .order(Arel.sql("#{date_group} DESC"))
                .limit(10)
                .pluck(
                    Arel.sql(date_group),
                    Arel.sql("SUM(request_count)")
                )
                .map do |date, request_count|
                    {
                        "xaxiskey" => date,
                        "yaxiskey" => request_count.to_i
                    }
                end
        end

        def top_controllers
            filtered_requests
                .group(:request_controller)
                .order(Arel.sql("SUM(request_count) DESC"))
                .limit(LIMIT)
                .pluck(
                    :request_controller,
                    Arel.sql("SUM(request_count)")
                )
                .map do |controller, request_count|
                    {
                        "request_controller" => controller,
                        "requests" => request_count.to_i
                    }
                end
        end

        def operating_systems
            distribution(:agent_platform, :operating_system) do |operating_system|
                icon_for(operating_system, PLATFORM_ICONS, "computer-fill")
            end
        end

        def devices
            distribution(:agent_device, :device) do |device|
                DEVICE_ICONS.fetch(device.to_s, DEVICE_ICONS.fetch("unknown"))
            end
        end

        def browsers
            distribution(:agent_browser, :browser) do |browser|
                icon_for(browser, BROWSER_ICONS, "global-fill")
            end
        end

        def build_dashboard
            {
                summary: summary,
                request_trend: request_trend,
                top_controllers: top_controllers,
                browsers: browsers,
                devices: devices,
                operating_systems: operating_systems
            }
        end

        def cache_enabled?
            Rails.env.production?
        end

        def cache_store
            Rails.cache
        end

        def cache_key
            # The date prevents a cached "day" period from crossing midnight,
            # even when the one-hour TTL has not expired yet.
            [
                "lesli_audit",
                "analytics",
                "v#{CACHE_VERSION}",
                account.id,
                selected_period,
                Date.current.iso8601
            ].join("/")
        end

        def account
            @account ||= current_user.account.audit
        end

        def filtered_requests
            apply_time_filter(account.account_requests)
        end

        def filtered_devices
            apply_time_filter(account.account_devices)
        end

        def daily_date_group
            return "strftime('%Y-%m-%d', date)" if ActiveRecord::Base.connection.adapter_name == "SQLite"

            "DATE_TRUNC('day', date)"
        end

        def distribution(column, value_key)
            counts = filtered_devices.group(column).sum(:agent_count)
            total = counts.values.sum

            counts.map do |value, count|
                {
                    value_key => value,
                    count: count,
                    icon: yield(value),
                    percentage: percentage(count, total)
                }
            end
        end

        def percentage(count, total)
            return 0 if total.zero?

            ((count.to_f / total) * 100).round
        end

        def icon_for(value, icons, default)
            match = icons.find { |pattern, _icon| value.to_s.match?(pattern) }
            match ? match.last : default
        end

        def apply_time_filter(relation)
            start_date = case selected_period
            when "day" then Date.current
            when "week" then 6.days.ago.to_date
            when "month" then 29.days.ago.to_date
            when "sixmonth" then 6.months.ago.to_date
            when "year" then 1.year.ago.to_date
            end

            start_date ? relation.where(date: start_date..) : relation
        end

        def selected_period
            period = query[:bytime].to_s
            PERIODS.include?(period) ? period : "all"
        end
    end
end
