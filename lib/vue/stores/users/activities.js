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
export const useUsersActivities = defineStore("usersActivities", {
    state: () => {
        return {
            loading: false,
            pagination: {}, 
            records: [],
            columns: [{
                field: "id",
                label: "User Id"
            }, {
                field: "email",
                label: "Email"
            }, {
                field: "field_name",
                label: "Column"
            }, {
                field: "value_from",
                label: "From"
            }, {
                field: "value_to",
                label: "To"
            }, {
                field: "category",
                label: "Category"
            }, {
                field: "created_at_date",
                label: "Date"
            }]
        }
    },
    actions: {

        fetchIfEmpty() {
            if (this.records.length <= 0) {
                this.fetch()
            }
        },

        fetch() {
            this.$reset()
            this.loading = true
            this.http.get(this.url.audit("users/activities")).then(result => {
                this.records = result.records
                this.pagination = result.pagination
            }).catch(error => {

            }).finally(() => {
                this.loading = false
            })
        }

    }
})
