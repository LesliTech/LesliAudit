<script setup>
/*
Lesli

Copyright (c) 2023, Lesli Technologies, S. A.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see http://www.gnu.org/licenses/.

Lesli · Ruby on Rails SaaS Development Framework.

Made with ♥ by https://www.lesli.tech
Building a better future, one line of code at a time.

@contact  hello@lesli.tech
@website  https://www.lesli.tech
@license  GPLv3 http://www.gnu.org/licenses/gpl-3.0.en.html

// · ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~     ~·~
// · 
*/


// · 
import { onMounted } from "vue"


// · 
import { useUsers } from "Lesli/stores/users"


// · 
const storeUsers = useUsers()


// · 
const props = defineProps({
    component: {
        type: Object,
        required: true
    }
})


// · 
onMounted(() => {
    storeUsers.getUsersList()
})

</script>
<template>
    <lesli-card>    
        <h6 class="title is-6 mb-4">{{ props.component.name }}</h6>
        <p>{{ storeUsers.list.length }}</p>
    </lesli-card>
</template>
<style scoped>
    p {
        font-size: 2rem;
    }
</style>
