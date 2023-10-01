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
export const useUsersWorkingHours = defineStore("userWorkingHours", {
    state: () => {
        return {
            loading: false,
            pagination: {}, 
            records: [],
            columns: [{
                field: "id",
                label: "ID"
            },{
                field: "email",
                label: "Email"

            },{
                field: "name",
                label: "Role"

            },
            {
                field: "date",
                label: "Date",
                sort: true
            },{
                field: "first_activity",
                label: "First activity at",
                sort: true
            },{
                field: "last_activity",
                label: "Last activity at",
                sort: true
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
            this.fetch(this.url.audit("users/working_hours").search(string))
        },

        sort(column, direction){
            this.fetch(this.url.audit("users/working_hours").order(column, direction), false)
        },

        fetch(url=this.url.audit("users/working_hours")) {
            this.$reset()
            this.loading = true
            this.http.get(url).then(result => {
                this.records = result.map(({date, first_activity, last_activity, ...activity}) =>
                    ({
                        ...activity,
                        date: this.date.date(date),
                        first_activity: this.date.time(first_activity),
                        last_activity: this.date.time(last_activity)
                    })
                )
            }).catch(error => {
                this.msg.danger("Error while trying to fetch data")
            }).finally(() => {
                this.loading = false
            })
        }

    }
})
