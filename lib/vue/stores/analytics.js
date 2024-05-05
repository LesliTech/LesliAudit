/*

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

Made with ♥ by LesliTech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
*/


// · 
import { defineStore } from "pinia"


// · 
export const useAnalytics = defineStore("analytics", {
    state: () => {
        return {
            users: {
                loading: false,
                pagination: {}, 
                records: [],
                columns: [{
                    field: 'email',
                    label: 'User'
                }, {
                    field: 'resources',
                    label: 'Resources'
                }, {
                    field: 'requests',
                    label: 'Requests'
                }]
            },
            visitors: {
                loading: false,
                pagination: {}, 
                records: []
            },
            controllers: {
                loading: false,
                pagination: {}, 
                records: [],
                columns: [{
                    field: 'request_controller',
                    label: 'Controller'
                }, {
                    field: 'requests',
                    label: 'Requests'
                }]
            },
            trends: {
                loading: false,
                recordsDays: [],
                recordsHours: []
            }
        }
    },
    actions: {

        fetchVisits() {
            this.visitors.loading = true
            this.http.get(this.url.audit("analytics/visitors")).then(result => {
                this.visitors.records = result.map(record => {
                    record.date = this.date(record.date).date()
                    return record
                }).reverse()
            }).finally(() => {
                this.visitors.loading = false
            })
        },

        fetchUsers() {
            this.users.loading = true
            this.http.get(this.url.audit("analytics/users")).then(result => {
                this.users.records = result
            }).finally(() => {
                this.users.loading = false
            })
        },

        fetchControllers() {
            this.controllers.loading = true
            this.http.get(this.url.audit("analytics/controllers")).then(result => {
                this.controllers.records = result
            }).finally(() => {
                this.controllers.loading = false
            })
        },

        time(period,initalDate, endDate){
            this.http.get(this.url.audit("analytics/trends")
            .filter({ groupBy: [period], startDate: [initalDate], finalDate: [endDate] }))
            .then(result => {
                if (period ==='day'){
                    this.trends.recordsDays = result
                } else if (period ==='hour'){
                    this.trends.recordsHours = result
                } 
            }).finally(() => {
                this.loading = false
            })
        }
    }
})
