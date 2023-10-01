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
import { useAccountsActivities } from "CloudAudit/stores/accounts/activities"


// · implement stores
const storeAccountsActivities = useAccountsActivities()


// · initializing
onMounted(() => {
    storeAccountsActivities.fetchIfEmpty()
})

</script>
<template>
    <section class="application-component">
        <lesli-header title="Account activities"></lesli-header>
        <lesli-toolbar @reload="storeAccountsActivities.fetch()" @search="storeAccountsActivities.search"></lesli-toolbar>
        <lesli-table
            :columns="storeAccountsActivities.columns"
            :records="storeAccountsActivities.records">
        </lesli-table>        
    </section>
</template>

