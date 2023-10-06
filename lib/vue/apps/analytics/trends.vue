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


// . import Lesli components
import chartBar from "Lesli/components/charts/bar.vue"
import chartLine from "Lesli/components/charts/line.vue"


// · import lesli stores
import { useAnalytics } from "CloudAudit/stores/analytics"


// · implement stores
const storeAnalytics = useAnalytics()


// · define variables
var daySeries = ref([]);
var dayLabels = ref([]);
var timeSeries = ref([]);
var timeLabels = ref([]);
var days = {"Monday":0,"Tuesday":0,"Wednesday":0,"Thursday":0,"Friday":0,"Saturday":0,"Sunday":0}
var hours  = {};
var finalDate = ref("");
var startDate = ref("");


// · initializing
onMounted(() => {
    storeAnalytics.time('day',startDate.value,finalDate.value)
    storeAnalytics.time('hour',startDate.value,finalDate.value)
})


// · 
watch(() => storeAnalytics.trends.recordsDays, () => {
    days = {"Monday":0,"Tuesday":0,"Wednesday":0,"Thursday":0,"Friday":0,"Saturday":0,"Sunday":0}

    if(storeAnalytics.trends.recordsDays){
        storeAnalytics.trends.recordsDays.forEach((record) => {
            days[record.day] += record.count
        })
    } else {
        storeAnalytics.msg.info("There is no information for this date range")
    }

    dayLabels.value = Object.keys(days)
    daySeries.value = [{
        name: "Requests",
        data: Object.values(days)
    }]

    daySeries.value = Object.values(days)

})


// · 
watch(() => storeAnalytics.trends.recordsHours, () => {
    hours = {}
    if(storeAnalytics.trends.recordsHours){
        storeAnalytics.trends.recordsHours.forEach((record) => {
            hours [record.hour+":00"] = record.count
        })
    }

    timeLabels.value = Object.keys(hours)
    timeSeries.value = [{
        name: "Requests",
        data: Object.values(hours)
    }]
})


// Update date range when date picker change
function updateDates(){
    if (startDate.value != "" && finalDate.value != "") {

        if (startDate.value >= finalDate.value){
            storeAnalytics.msg.danger("Select valid range for date")
        } else {
            storeAnalytics.time('day',startDate.value,finalDate.value)
            storeAnalytics.time('hour',startDate.value,finalDate.value)

        }
    }
}

</script>
<template>
    <section class="application-component">
        <lesli-header title="Trends">
        </lesli-header>

        <!--
        <div class="grid-container">
            <div class="grid-item">
                <label>From</label>
                <br/>
                <input class="input is-info" type="date" v-model="startDate" @change="updateDates">
            </div>
            <div class="grid-item">
                <label>To</label>
                <br/>
                <input class="input is-info" type="date" v-model="finalDate" @change="updateDates" />
            </div>
        </div>
        -->
        <div class="card mb-5">
            <div class="card-content">
                <chartBar
                    title="Requests by day of the week"
                    :series="daySeries"
                    :labels="dayLabels">
                </chartBar>
            </div>
        </div>

        <div class="card">
            <div class="card-content">
                <chartLine
                    title="Requests by time of the day"
                    :series="timeSeries"
                    :labels="timeLabels">
                </chartLine>
            </div>
        </div>
    </section>
</template>
