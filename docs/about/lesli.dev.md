<header align="center" class="lesli-markdown-header">
    <img width="75" class="engine-logo" alt="LesliCalendar logo" src="../app/assets/images/lesli_calendar/calendar-logo.svg" />
    <h1 align="center">
        Unified calendar app for<br />
        <span class="lesli-title-colored">Lesli Framework.</span>
    </h1>
</header>

<hr/>

### Quick start

```shell
# Add lesli_calendar engine
bundle add lesli_calendar
```

```shell
# Setup database
rake lesli:db:setup
```

```ruby
# Load lesli_calendar
Rails.application.routes.draw do
    mount lesli_calendar::Engine => "/calendar"
end
```
