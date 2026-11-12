require "test_helper"

module LesliAudit
    class TrafficViewTest < ActiveSupport::TestCase
        test "renders synchronization status, both trend series, and the other breakdown" do
            html = I18n.with_locale(:en) do
                LesliAudit::TrafficController.render(
                    template: "lesli_audit/traffic/index",
                    layout: false,
                    assigns: traffic_assigns
                )
            end

            document = Nokogiri::HTML.fragment(html)
            chart = document.at_css("script[data-lesli-chart-config]")
            chart_config = JSON.parse(chart["data-lesli-chart-config"])

            assert_includes html, "Cloudflare"
            assert_includes html, "Last synchronization"
            assert_includes html, "Other"
            assert document.at_css('[role="alert"]')
            assert_equal [ "Page views", "Visits" ], chart_config.fetch("datasets").pluck("label")
        end

        private

        def traffic_assigns
            {
                summary: {
                    page_views: 120,
                    visits: 80,
                    resources: 1,
                    tracked_paths: 1
                },
                trend: [
                    { date: Date.current, page_views: 120, visits: 80 }
                ],
                paths: [{
                    "hostname" => "example.com",
                    "path" => "/demo",
                    "provider" => "Cloudflare",
                    "page_views" => 120,
                    "visits" => 80
                }],
                resources: [{
                    "resource" => "Profile #27",
                    "page_views" => 120,
                    "visits" => 80
                }],
                countries: [{
                    value: "other",
                    page_views: 20,
                    visits: 10,
                    percentage: 16.7,
                    other: true
                }],
                devices: [],
                referrers: [],
                synchronization: {
                    source: "Cloudflare",
                    last_synced_at: 2.days.ago,
                    stale: true
                }
            }
        end
    end
end
