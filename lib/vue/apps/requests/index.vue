<script setup>
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


// · import vue tools
import { ref, reactive, onMounted, watch, computed } from "vue"


// · import lesli stores
import { useLogRequest } from "CloudAudit/stores/request"


// · implement stores
const store = useLogRequest()


// · define variables
const columns = [{
    field: "id",
    label: "ID"
}, {
    field: "email",
    label: "Email",
    sort: true
}, {
    field: "request_agent",
    label: "Device"
}, {
    field: "request_method",
    label: "Method"
}, {
    field: "request_controller",
    label: "Controller",
    sort: true
}, {
    field: "request_action",
    label: "Action"
}, {
    field: "created_at_date",
    label: "Date"
}]


// · initializing
onMounted(() => {
    store.fetchLogsIfEmpty()
})


function itemProjection(item){ console.log("itemprojection", item) }
function selectItemEventHandler(item){ console.log("selectItem", item) }
function onInputEventHandler(item){ console.log("onInput", item) }
function onFocusEventHandler(item){ console.log("onFocus", item) }
function onBlurEventHandler(item){ console.log("onBlur", item) }

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
    <section class="application-component">
        <lesli-header
            title="Users activity"
            @reload="store.fetchLogs()">
        </lesli-header>
        <lesli-toolbar @search="store.search">
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
            @sort="store.sort"
            @paginate="store.paginate"
            :pagination="store.pagination"
            :loading="store.loading"
            :columns="columns"
            :records="store.records"
            @click="showUser">
        </lesli-table>
    </section>
</template>
