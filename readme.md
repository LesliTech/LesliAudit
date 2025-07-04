<div align="center" class="documentation-header">
    <img width="100" alt="LesliAudit logo" src="./app/assets/images/lesli_audit/audit-logo.svg" />
    <h3 align="center">Logs Activities & Analytics for The Lesli Framework</h3>
</div>


<br />
<hr/>

<div align="center" class="documentation-statics">
    <a target="blank" href="https://rubygems.org/gems/lesli">
        <img height="22" alt="Gem Version" src="https://badge.fury.io/rb/lesli.svg"/>
    </a>
    <a class="mx-2" href="https://codecov.io/github/LesliTech/Lesli"> 
        <img height="22" src="https://codecov.io/github/LesliTech/Lesli/graph/badge.svg?token=2O12NENK5Y"/> 
    </a>
    <a href="https://codecov.io/github/LesliTech/LesliBabel"> 
        <img height="22" src="https://sonarcloud.io/api/project_badges/measure?project=LesliTech_LesliBabel&metric=sqale_rating"/> 
    </a>
</div>

<hr/>
<br />


### Quick start

```shell
# Add LesliAudit engine gem
bundle add lesli_audit
```

```shell
# Setup & initialize the database
rake lesli:db:setup
```

```ruby
# Load LesliAudit engine
Rails.application.routes.draw do
    mount LesliAudit::Engine => "/audit"
end
```


### Documentation



### Lesli Documentation
* [website](https://www.lesli.dev/)
* [documentation](https://www.lesli.dev/engines/audit/)


### Get in touch with Lesli

* [Email: hello@lesli.tech](hello@lesli.tech)
* [Website: https://www.lesli.tech](https://www.lesli.tech)
* [Twitter: @LesliTech](https://twitter.com/LesliTech)


### License
-------
Copyright (c) 2025, Lesli Technologies, S. A.

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

<hr />
<br />

<div align="center" class="has-text-centered">
    <img width="200" alt="Lesli logo" src="https://cdn.lesli.tech/lesli/brand/app-logo.svg" />
    <h4 align="center" class="mt-0">Ruby on Rails SaaS Development Framework.</h4>
</div>
