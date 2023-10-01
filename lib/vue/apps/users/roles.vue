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
import chartBar from "Lesli/components/charts/bar.vue"


// · import stores
import { useUsersRoles } from "CloudAudit/stores/users/roles"


// · implement stores
const storeUsersRoles = useUsersRoles()


// · define variables
const usersByRole = ref([]);


// · initializing
onMounted(() => {
    storeUsersRoles.fetchIfEmpty()
})


// · users by role
watch(() => storeUsersRoles.records, () => {
    usersByRole.value = []
    storeUsersRoles.records.forEach(role => {
        usersByRole.value.push({
            x: role.name,
            y: role.users
        })
    })
})

</script>
<template>
    <section class="application-component">
        <lesli-header title="Users by role" @reload="storeRegistration.reload()">
        </lesli-header>
        <div class="card">
            <div class="card-content">
                <chartBar :series="usersByRole">
                </chartBar>
            </div>
        </div>
    </section>
</template>

