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
import application from "Lesli/application"
import appAnalytics from "LesliAudit/apps/analytics/index.vue"
import appRequests from "LesliAudit/apps/requests/index.vue"

// · 
/*
import dashboard from "Lesli/shared/dashboards/apps/show.vue"
import appUsersRegistrations from "CloudAudit/apps/users/registrations.vue"
import appUsersWorkingHours from "CloudAudit/apps/users/workingHours.vue"
import appUsersActivities from "CloudAudit/apps/users/activities.vue"
import appUsersLogs from "CloudAudit/apps/users/logs.vue"
import appUsersRoles from "CloudAudit/apps/users/roles.vue"

import appAnalyticsVisitors from "CloudAudit/apps/analytics/visitors.vue"
import appAnalyticsTrends from "CloudAudit/apps/analytics/trends.vue"

import appAccountsActivities from "CloudAudit/apps/accounts/activities.vue"

import appSecuritySessions from "CloudAudit/apps/security/sessions.vue"
import appSecurityPasswords from "CloudAudit/apps/security/passwords.vue"    
*/


// · 
application("LesliAudit", [{
    path: "/analytics",
    component: appAnalytics, 
    props: { engine: "audit" }
}, {
    path: "/requests",
    component: appRequests
}
/*{
    path: "/",
    component: dashboard, 
    props: { engine: "audit" }
}, {
    path: "/users/working_hours",
    component: appUsersWorkingHours, 
}, {
    path: "/users/activities",
    component: appUsersActivities, 
}, {
    path: "/users/logs",
    component: appUsersLogs, 
}, {
    path: "/users/registrations",
    component: appUsersRegistrations, 
}, {
    path: "/users/roles",
    component: appUsersRoles, 
}, {
    path: "/accounts/activities",
    component: appAccountsActivities, 
}, {
    path: "/analytics/visitors",
    component: appAnalyticsVisitors, 
}, {
    path: "/analytics/trends",
    component: appAnalyticsTrends
}, {
    path: "/security/sessions",
    component: appSecuritySessions
}, {
    path: "/security/passwords",
    component: appSecurityPasswords
}*/])
