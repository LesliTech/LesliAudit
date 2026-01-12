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

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end



# Get the current date
end_date = Date.today

# Calculate the date 10 days ago
start_date = 10.days.ago.to_date

account = Lesli::Account.first

current_user = Lesli::User.first

# controllers to seed
[
    "Macintosh", 
    "Windows"
].each do |platform|

    [
        "Firefox", 
        "Chrome",
        "Safari"
    ].each do |browser|
        # Iterate through the dates
        (start_date..end_date).each do |date|

            current_user.account.audit.devices.create_with(
                :agent_count => rand(40..80),
            ).find_or_create_by(
                :agent_platform => platform,
                :agent_browser => browser,
                :created_at => date,
            )
        end
    end
end
