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
    class VisitorService < Lesli::ApplicationLesliService

        def visits
            requests = apply_time_filter(current_user.account.audit.account_requests)

            controllers, total_requests = requests.pick(
                Arel.sql("COUNT(DISTINCT request_controller)"),
                Arel.sql("SUM(request_count)")
            )

            {
                controllers: controllers.to_i,
                requests: total_requests.to_i
            }
        end 

        def traffic
            #Rails.cache.fetch(cache_key_for_account(__method__), expires_in: 1.hour) do 
                group = 'day' 
                #group = params[:bygroup] if ['month','week','day'].include?(params[:bygroup])

                group_by = "DATE_TRUNC('month', date)" if group == 'month'
                group_by = "DATE_TRUNC('week', date)" if group == 'week'
                group_by = "DATE_TRUNC('day', date)" if group == 'day'

                # compatibility for SQLite
                if ActiveRecord::Base.connection.adapter_name == "SQLite"
                    group_by = "strftime('%Y-%m-%d', date)"
                end

                requests = apply_time_filter(current_user.account.audit.account_requests)
                .group(group_by)
                
                requests.limit(10).order("xaxiskey desc").select(
                    "sum(request_count) yaxiskey",
                    "#{group_by} xaxiskey"
                ).as_json
            #end
        end 

        def requests
            requests = apply_time_filter(current_user.account.audit.account_requests)
            .group("request_controller")

            requests = requests.limit(LIMIT).order("requests DESC").select(
                :request_controller,
                "sum(request_count) requests"
            ).as_json
        end

        def os 
            device_counts = apply_time_filter(current_user.account.audit.account_devices)
            .group(:agent_platform)
            .sum(:agent_count)

            total = device_counts.values.sum

            device_counts.map do |device, count|
                {
                    device: device,
                    count: count,
                    icon: platform_icon(device),
                    percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round()
                }
            end
        end 

        def devices 
            device_counts = apply_time_filter(current_user.account.audit.account_devices)
            .group(:agent_device)
            .sum(:agent_count)

            total = device_counts.values.sum

            device_counts.map do |device, count|
                {
                    device: device,
                    count: count,
                    icon: device_icon(device),
                    percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round()
                }
            end
        end 

        def browsers
            browser_counts = apply_time_filter(current_user.account.audit.account_devices)
            .group(:agent_browser)
            .sum(:agent_count)

            total = browser_counts.values.sum

            browser_counts.map do |browser, count|
                {
                    browser: browser,
                    count: count,
                    icon: browser_icon(browser),
                    percentage: total.zero? ? 0 : ((count.to_f / total) * 100).round()
                }
            end
            #Rails.cache.fetch(cache_key_for_account(__method__), expires_in: 4.hour) do 
                # current_user.account.audit.account_devices
                # .group(:agent_browser, :date)
                # .select(
                #     'date as xaxiskey',
                #     'agent_browser as dataname',
                #     'sum(agent_count) as yaxiskey'
                # ).as_json
            #end
        end

        private 

        LIMIT=15

        DEFAULT_PLATFORM_ICON_CLASS = "computer-fill"
        PLATFORM_ICON_CLASSES = {
            /chrome os|cros/i           => "chrome-fill",
            /ios|ipad|iphone|mac/i      => "apple-fill",
            /windows/i                  => "windows-fill",
            /ubuntu/i                   => "ubuntu-fill",
            /debian|fedora|linux/i      => "linux-fill",
            /android/i                  => "android-fill"
        }.freeze

        DEFAULT_BROWSER_ICON_CLASS = "global-fill"
        BROWSER_ICON_CLASSES = {
            /chrome|chromium/i        => "chrome-fill",
            /firefox/i                => "firefox-fill",
            /safari/i                 => "safari-fill",
            /edge/i                   => "edge-fill",
            /opera|opr/i              => "opera-fill",
            /internet explorer|msie/i => "ie-fill",
            /brave/i                  => "brave-fill"
        }.freeze

        DEVICE_ICON_CLASSES = {
            "desktop"       => "mac-line",
            "tablet"        => "tablet-line",
            "smartphone"    => "smartphone-line",
            "unknown"       => "file-unknow-line"
        }.freeze

        def platform_icon(platform)
            return DEFAULT_PLATFORM_ICON_CLASS if platform.blank?

            match = PLATFORM_ICON_CLASSES.find do |pattern, _icon_class|
                platform.match?(pattern)
            end

            match ? match.last : DEFAULT_PLATFORM_ICON_CLASS
        end

        def browser_icon(browser)
            return DEFAULT_BROWSER_ICON_CLASS if browser.blank?

            match = BROWSER_ICON_CLASSES.find do |pattern, _icon_class|
                browser.match?(pattern)
            end

            match ? match.last : DEFAULT_BROWSER_ICON_CLASS
        end

        def device_icon(device)
            DEVICE_ICON_CLASSES.fetch(device.to_s, DEVICE_ICON_CLASSES["unknown"])
        end

        def apply_time_filter(relation)
            start_date = case query[:bytime]
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
