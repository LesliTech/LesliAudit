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

LesliAudit::Engine.routes.draw do


    # Dashboard alias
    root to: "dashboards#show"
    

    # Dashboard:
    #   Total users
    #   Total roles
    #   Visits
    #   Trends
    resource :dashboard, only: [:show]


    # Users:
    #   Registrations   users grouped by creation date
    #   Working hours   first and last request of the day
    #   Activities      changes on users information
    #   Roles           total users by role
    #   Logs            relevant actions of users
    resources :users, only: []


    # Analytics:
    resources :analytics, only: [:index] do 
        collection do 
            get :trends
            get :controllers
            get :visitors
            get :devices
            get :users
        end
    end


    # Account:
    #   Activities      changes on account information
    #   Logs            relevant actions of the account
    resources :account, only: []


    # Requests:         Raw request data
    resources :requests, only: [:index]

end
