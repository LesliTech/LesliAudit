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


// · import Lesli components
import chartLine from "Lesli/components/charts/line.vue"


// · import stores
import { useUsersWorkingHours } from "CloudAudit/stores/users/working_hours"


// · implement stores
const storeUsersWorkingHours = useUsersWorkingHours()


// · initializing
onMounted(() => {
    storeUsersWorkingHours.fetch()
})

</script>
<template>
    <application-component>
        <lesli-header title="Working hours"></lesli-header>
        <lesli-toolbar @search="storeUsersWorkingHours.search"></lesli-toolbar>
        <lesli-table
            :columns="storeUsersWorkingHours.columns"
            :records="storeUsersWorkingHours.records"
            @sort="storeUsersWorkingHours.sort">
        </lesli-table>
    </application-component>
</template>
