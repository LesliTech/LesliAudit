<script setup>

// · import vue tools
import { ref, reactive, onMounted, watch, computed } from "vue"


// · import stores
import { useAnalytics } from "LesliAudit/vue/stores/analytics"


// · implement stores
const storeAnalytics = useAnalytics()


// · 
import visitors from "../../components/visitors.vue";
import requests from "../../components/requests.vue";
//import trends from "./trends.vue";


// · 
function reload() {
    storeAnalytics.fetch()
}


// · initializing
onMounted(() => {
    storeAnalytics.fetchVisits()
    setTimeout(() => storeAnalytics.fetchUsers(), 600)
    setTimeout(() => storeAnalytics.fetchControllers(), 1200)
})

</script>
<template>
    <lesli-application-container>
        <lesli-header title="Analytics">
            <lesli-select :options="[
                { label: 'Today', value: 7 },
                { label: 'Yesterday', value: 7 },
                { label: 'This week', value: 7 },
                { label: 'Last 7 days', value: 7 },
                { label: 'Last 15 days', value: 7 },
                { label: 'Last 30 days', value: 7 },
                { label: 'Last 60 days', value: 7 },
                { label: 'Last 90 days', value: 7 },
                { label: 'Last 6 months', value: 7 },
                { label: 'Last 12 months', value: 7 },
                { label: 'This year (Jan - Today)', value: 7 }
            ]">
            </lesli-select>
        </lesli-header>
        <visitors class="mb-6"></visitors>
        <requests></requests>
    </lesli-application-container>
</template>
