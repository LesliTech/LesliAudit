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
import { onMounted } from "vue"


// · import lesli stores
import { useSecurityPassword } from "CloudAudit/stores/security/password"


// · implement lesli stores
const store = useSecurityPassword()


// · initializing
onMounted(() => {
    store.fetchIfEmpty()
})

</script>
<template>
    <section class="application-component">
        <lesli-header
            title="Restore password emails"
            @reload="store.fetch()">
        </lesli-header>
        <lesli-toolbar @search="store.search"></lesli-toolbar>
        <lesli-table
            :pagination="store.pagination"
            :loading="store.loading"
            :columns="store.columns"
            :records="store.records">
        </lesli-table>
    </section>
</template>
