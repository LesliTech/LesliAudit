
<p align="center">
    <img width="70" alt="Lesli logo" src="../app/assets/images/lesli_audit/audit-logo.svg" />
</p>

<h3 align="center">Lesli Audit database</h3>

### 05.01. Audit
```plaintext
00.01. audit/account

05.01. audit/dashboards 

10.01. audit/logs
11.01. audit/account_requests
12.01. audit/user_requests
13.01. audit/devices

```


<fieldset>

```mermaid
erDiagram
    audit_accounts {
        bigint   id
        integer  status
        datetime deleted_at
        datetime timestamps 
    }

    audit_account_requests {
        string    request_controller
        string    request_action
        string    request_method
        integer   request_count
        date      created_at
    }

    audit_user_requests {
        integer   request_count
        date      created_at
        datetime  updated_at
    }

    audit_accounts ||--|| lesli_accounts : ""
    audit_account_requests }|--|| audit_accounts : ""
    audit_user_requests }|--|| audit_accounts : ""
    audit_user_requests ||--|| lesli_users : ""

```
</fieldset>
