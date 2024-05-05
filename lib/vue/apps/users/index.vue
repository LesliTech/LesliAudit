<script setup>
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


// · import vue tools
import { onMounted, ref } from "vue"


// · import stores
import componentRegistrations from "./registrations.vue"


// · import stores
import { useUsers } from "LesliAudit/vue/stores/users"


// · implement stores
const storeUsers = useUsers()


// · 
var selectedPeriod = ref("month");


// · 
function updateDate(){
    // filterPeriod = selectedPeriod.value;
    // storeUsersRegistrations.fetch(filterPeriod)
}

</script>
<template>
    <lesli-application-container>
        <lesli-header title="Users">
            <lesli-select
                id = "selectPeriod"
                @change="updateDate"
                v-model = "selectedPeriod"
                :options="[{
                    label: 'Year',
                    value: 'year'
                }, {
                    label: 'Month',
                    value: 'month'
                }, {
                    label: 'Week',
                    value: 'week'
                }, {
                    label: 'Day',
                    value: 'day'
                }]">
            </lesli-select>
        </lesli-header>
        <component-registrations>
        </component-registrations>
    </lesli-application-container>
</template>
<style>
</style>
