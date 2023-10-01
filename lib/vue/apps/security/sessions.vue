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
import { useSecuritySession } from "CloudAudit/stores/security/session"


// · implement lesli stores
const store = useSecuritySession()


// · initializing
onMounted(() => {
    store.fetchIfEmpty()
})

</script>
<script>
export default {
    methods: {
        // Method that allow to go to a user profile from the sessions table
        showUser(user) {
            this.url.admin("users/:id", user.id).go()
        }
    }
}
</script>
<template>
    <section class="application-component">
        <lesli-header
            title="User sessions"
            @reload="store.fetch()">
        </lesli-header>
        <lesli-toolbar @search="store.search"></lesli-toolbar>
        <lesli-table
            :pagination="store.pagination"
            :loading="store.loading"
            :columns="store.columns"
            :records="store.records"
            @click="showUser">
        </lesli-table>
    </section>
</template>
