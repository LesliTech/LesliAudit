# Installation & configuration

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
