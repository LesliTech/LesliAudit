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
import { useUsersRegistrations } from "CloudAudit/stores/users/registrations"


// · implement stores
const storeUsersRegistrations = useUsersRegistrations()


// · define variables
var registrationSeries = ref([]);
var registrationLabels = ref([]);
var selectedPeriod = ref("month");
var filterPeriod = ref("");
var selectOptions = ref([]);


// · initializing
onMounted(() => {
    storeUsersRegistrations.fetchIfEmpty()
    storeUsersRegistrations.getOptions()
})


// · 
watch(() => storeUsersRegistrations.periods, () => {
    selectOptions.value = storeUsersRegistrations.periods
})


// · 
watch(() => storeUsersRegistrations.records, () => {
    registrationLabels.value = storeUsersRegistrations.records.map(visit => visit.date)
    registrationSeries.value = [{
        name: "Users",
        data: storeUsersRegistrations.records.map(visit => visit.count)
    }]
})


// · 
function updateDate(){
    filterPeriod = selectedPeriod.value;
    storeUsersRegistrations.fetch(filterPeriod)
}

</script>
<template>
    <section class="application-component">
        <lesli-header title="User registered by date" @reload="storeUsersRegistrations.reload()">
        </lesli-header>

        <div class="block">
            <lesli-select
                id = "selectPeriod"
                @change="updateDate"
                v-model = "selectedPeriod"
                :options="selectOptions">
            </lesli-select>
        </div>
        <div class="card">
            <div class="card-content">
                <chartLine
                    :series="registrationSeries"
                    :labels="registrationLabels"
                    @marker-click="markerClick">
                </chartLine>    
            </div>
        </div>
    </section>
</template>

