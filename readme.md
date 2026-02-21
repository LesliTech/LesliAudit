<div align="center">
    <img width="100" alt="LesliAudit logo" src="./app/assets/images/lesli_audit/audit-logo.svg" />
    <h3 align="center">Activity, logs, security and more... for the Lesli Framework.</h3>
</div>

<br />
<hr/>

<div align="center">
    <a target="_blank" href="https://github.com/LesliTech/LesliAudit/actions">
        <img alt="Tests passing" src="https://img.shields.io/badge/Tests-passing-green?style=for-the-badge&logo=github">
    </a>
    <a target="_blank" href="https://rubygems.org/gems/lesli_audit">
        <img alt="Gem Version" src="https://img.shields.io/gem/v/lesli_audit?style=for-the-badge&logo=ruby">
    </a>
    <a target="_blank" href="https://codecov.io/github/LesliTech/LesliAudit">
        <img alt="Codecov" src="https://img.shields.io/codecov/c/github/LesliTech/LesliAudit?style=for-the-badge&logo=codecov">
    </a>
</div>

<hr/>
<br />

<div align="center">
    <img
        style="width:100%;max-width:800px;border-radius:6px;"
        alt="Lesli screenshot" src="./docs/images/screenshot.png" />
</div>

<br />
<hr/>
<br />

### Installation

```shell
# Add LesliAudit engine gem
bundle add lesli_audit

# Setup & initialize the database
rake lesli:db:setup
```

```ruby
# Load LesliAudit engine
Rails.application.routes.draw do
    mount LesliAudit::Engine => "/audit"
end
```

<br />
<hr/>
<br />

### Development 

```shell
# clone the lesli repo inside your engine folder: RailsApp/engines
git clone https://github.com/LesliTech/LesliAudit.git

# Load LesliAudit as a Gem
gem "lesli", path: "engines/LesliAudit"

# Install the necessary Gems to run LesliAudit
bundle install

# Setup & initialize the database
rake lesli:db:setup

```

<br />
<hr/>
<br />

### Demo

* [online demo](https://demo.lesli.dev/)
* [docker demo](https://github.com/LesliTech/lesli-docker-demo)


### Documentation
* [website](https://www.lesli.dev/)
* [documentation](https://www.lesli.dev/engines/audit)


### Connect with Lesli

* [X: @LesliTech](https://x.com/LesliTech)
* [Email: hello@lesli.tech](hello@lesli.tech)
* [Website: https://www.lesli.tech](https://www.lesli.tech)


### License
-------
Copyright (c) 2026, Lesli Technologies, S. A.

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

<br />
<hr />
<br />
<br />

<div align="center" class="has-text-centered">
    <img width="200" alt="Lesli logo" src="https://cdn.lesli.tech/lesli/brand/app-logo.svg" />
    <h3 align="center" class="mt-0">
        The Open-Source SaaS Development Framework for Ruby on Rails.
    </h3>
</div>

<br />
<br />
