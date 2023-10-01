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
import { useUsersActivities } from "CloudAudit/stores/users/activities"


// · implement stores
const storeUsersActivities = useUsersActivities()


// · initializing
onMounted(() => {
    storeUsersActivities.fetchIfEmpty()
})

</script>
<template>
    <application-component>
        <lesli-header title="Working hours"></lesli-header>
        <lesli-toolbar @search="storeUsersActivities.search"></lesli-toolbar>
        <lesli-table
            :pagination="storeUsersActivities.pagination"
            :columns="storeUsersActivities.columns"
            :records="storeUsersActivities.records"
            @sort="storeUsersActivities.sort">
        </lesli-table>
    </application-component>
</template>
