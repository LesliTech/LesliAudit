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
import { lesliChartBar } from "lesli-vue/components"


// · import stores
import { useUsers } from "LesliAudit/vue/stores/users"


// · implement stores
const storeUsers = useUsers()


// · define variables
var registrationSeries = ref([]);


// · initializing
onMounted(() => {
    storeUsers.getRegistrations()
})


// · 
watch(() => storeUsers.registrations, (oldData, newData) => {

    if (storeUsers.registrations.length == 0) {
        return 
    }

    registrationSeries.value = [{
        data: storeUsers.registrations.map(registration => {
            return {
                x: registration.date, 
                y: registration.count
            }
        })
    }]
})

</script>
<template>
    <section class="application-component">
        <lesli-card>
            <lesli-chart-bar
                title="Registrations by date"
                :series="registrationSeries"
                @marker-click="markerClick">
            </lesli-chart-bar> 
        </lesli-card>
    </section>
</template>

