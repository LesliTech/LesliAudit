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
export const useAccountsActivities = defineStore("accountsActivities", {
    state: () => {
        return {
            loading: false,
            pagination: {}, 
            records: [],
            columns: [{
                field: "id",
                label: "ID"
            }, {
                field: "title",
                label: "Title"
            }, {
                field: "description",
                label: "Description"
            }, {
                field: "system_process",
                label: "Process"
            }, {
                field: "system_module",
                label: "Module"
            }, {
                field: "created_at_date",
                label: "Date"
            },{
                field: "send_to",
                label: "Send to"
            }]
        }
    },
    actions: {

        fetchIfEmpty() {
            if (this.records.length <= 0) {
                this.fetch()
            }
        },

        search(string) {
            this.http.get(this.url.audit("accounts/activities").search(string)).then(result => {
                this.records = result.records
                this.pagination = result.pagination
            }).catch(error => {
                this.msg.danger("Error while trying to fetch data")
            }).finally(() => {
                this.loading = false
            })
        },

        fetch() {
            this.$reset()
            this.loading = true
            this.http.get(this.url.audit("accounts/activities")).then(result => {
                this.records = result.records
                this.pagination = result.pagination
            }).catch(error => {

            }).finally(() => {
                this.loading = false
            })
        }

    }
})
