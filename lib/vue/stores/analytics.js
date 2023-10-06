/*
Copyright (c) 2022, all rights reserved.

All the information provided by this platform is protected by international laws related  to 
industrial property, intellectual property, copyright and relative international laws. 
All intellectual or industrial property rights of the code, texts, trade mark, design, 
pictures and any other information belongs to the owner of this platform.

Without the written permission of the owner, any replication, modification,
transmission, publication is strictly forbidden.

For more information read the license file including with this software.

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
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
            devices: {
                loading: false,
                pagination: {}, 
                records: [],
                columns: [{
                    field: 'device',
                    label: 'Device'
                }, {
                    field: 'visits',
                    label: 'Visits'
                }]
            },
            resources: {
                loading: false,
                pagination: {}, 
                records: []
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
                this.visitors.records = result.reverse()
            }).finally(() => {
                this.visitors.loading = false
            })
        },

        fetchResources() {
            this.resources.loading = true
            this.http.get(this.url.audit("analytics/resourcess")).then(result => {
                this.resources.records = result.reverse()
            }).finally(() => {
                this.resources.loading = false
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

        fetchDevices() {
            this.devices.loading = true
            this.http.get(this.url.audit("analytics/devices")).then(result => {
                this.devices.records = result
            }).finally(() => {
                this.devices.loading = false
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
