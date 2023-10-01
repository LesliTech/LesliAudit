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
export const useLogRequest = defineStore("logRequest", {
    state: () => {
        return {
            date: "",
            loading: false,
            pagination: {}, 
            records: []
        }
    },
    actions: {

        search(string) {
            console.log(string)
            this.fetchLogs(this.url.audit("requests").search(string), false)
        },

        sort(column, direction) {
            this.fetchLogs(this.url.audit("requests").order(column, direction), false)
        },

        paginate(page) {
            this.fetchLogs(this.url.audit("requests").paginate(page), false)
        },

        fetchLogsIfEmpty() {
            if (this.records.length <= 0) {
                this.fetchLogs()
            }
        },

        fetchLogs(url=this.url.audit("requests"), loading=true) {

            this.loading = loading

            this.http.get(url).then(result => {
                this.records = result.records
                this.pagination = result.pagination
            }).catch(error => {

            }).finally(() => {
                this.loading = false
            })

        }

    }
})
