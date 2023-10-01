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


// · import stores
import { useUsersLogs } from "CloudAudit/stores/users/logs"


// · implement stores
const storeUsersLogs = useUsersLogs()


// · initializing
onMounted(() => {
    storeUsersLogs.fetchIfEmpty()
})

</script>
<template>
    <application-component>
        <lesli-header title="User logs"></lesli-header>
        <lesli-toolbar @search="storeUsersLogs.search"></lesli-toolbar>
        <lesli-table
            :pagination="storeUsersLogs.pagination"
            :columns="storeUsersLogs.columns"
            :records="storeUsersLogs.records"
            @sort="storeUsersLogs.sort">
        </lesli-table>
    </application-component>
</template>
