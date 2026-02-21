=begin

Lesli

Copyright (c) 2025, Lesli Technologies, S. A.

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

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
=end

LesliAudit::Engine.routes.draw do

    Lesli::Router.mount_lesli_engine_routes(self)

    # Users:
    #   Registrations   users grouped by creation date
    #   Working hours   first and last request of the day
    #   Activities      changes on users information
    #   Roles           total users by role
    #   Logs            relevant actions of users
    resources :users, only: [:index] 

    # Analytics:
    #   Visitors by date
    #   Trends by date
    #   Most active users
    #   Most active controllers
    resources :analytics, only: [:index] 

    resources :logs, only: [:index, :show]

    resources :requests, only: [:index]

    resources :devices, only: [:index]
end
