<script setup>

// · import vue tools
import { ref, reactive, onMounted, watch, computed } from "vue"


import visitors from "./visitors.vue";
import requests from "./requests.vue";
//import trends from "./trends.vue";

</script>
<template>
    <lesli-application-container>
        <lesli-header title="Analytics"></lesli-header>
        <visitors></visitors>
        <requests></requests>
    </lesli-application-container>
</template>
