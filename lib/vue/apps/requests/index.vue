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

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
*/


// · import vue tools
import { ref, reactive, onMounted, watch, computed } from "vue"


// · import lesli stores
import { useRequests } from "LesliAudit/vue/stores/request"


// · implement stores
const storeRequests = useRequests()


// · define variables
const columns = [{
    field: "id",
    label: "ID"
}, {    
    field: "request_controller",
    label: "Controller",
    sort: true
}, {
    field: "request_action",
    label: "Action"
}, {
    field: "request_count",
    align: "center",
    label: "Count"
}, {
    field: "created_at",
    label: "Date"
}]


// · initializing
onMounted(() => {
    storeRequests.fetch()
})

</script>
<script>
export default {
    methods: {
        showUser(user) {
            this.url.admin("users/:id", user.id).go()
        }
    }
}
</script>
<template>
    <lesli-application-container>
        <lesli-header
            title="Account requests"
            @reload="storeRequests.fetchLogs()">
        </lesli-header>
        <lesli-toolbar @search="storeRequests.search">
            <!--
            <Autocomplete
                id="typeahead_id"
                placeholder="Start writing..."
                :items="[{
                    'id': 1,
                    'first_name': 'Geneva',
                    'last_name': 'Baniard',
                    'email': 'gbaniard0@tiny.cc',
                    'gender': 'Male',
                    'ip_address': '173.141.4.168'
                }]"
                :minInputLength="1"
                :itemProjection="
						(item) => {
							return item.email;
						}
					"
                @selectItem="selectItemEventHandler"
                @onInput="onInputEventHandler"
                @onFocus="onFocusEventHandler"
                @onBlur="onBlurEventHandler">
            </Autocomplete>
            -->
        </lesli-toolbar>
        <lesli-table
            @sort="storeRequests.sort"
            @paginate="storeRequests.paginate"
            :pagination="storeRequests.pagination"
            :loading="storeRequests.loading"
            :columns="columns"
            :records="storeRequests.records"
            @click="showUser">
        </lesli-table>
    </lesli-application-container>
</template>
