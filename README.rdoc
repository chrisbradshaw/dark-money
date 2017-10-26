# darkmoney 1.0.0

dark$ is a dynamic, sortable data visualization platform illustrating Members of Congress voting record and donor contributions rendered utilizing d3.js

**Sources**

* [Sunlight Labs API](https://sunlightfoundation.com/api/) - information on members of Congress and federal legislation
* [OpenSecrets.org](https://www.opensecrets.org/) - industry contribution data
* [GovTrack.us](https://www.govtrack.us) - tracking legislation and votes in the United States Congress.


## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

```
Ruby Version 2.3.0
Rails Version 4.2.5
```

### Installing

How to get development env running:

Make sure the correct versions of Ruby and Rails are installed on your system. Fire command prompt and run command:

```
ruby -v && rails -v
```

Clone darkmoney git repository

```
git clone git@github.com:chrisbradshaw/dark-money.git
```

Install all dependencies

```
bundle install
```

Create db and migrate schema

```
rake db:create
rake db:migrate
```

Don't forget to open PostgreSQL

```
rails s
```

Navigate to localhost:3000 in your browser. 

## Built With

* [d3.js](https://d3js.org/) - javascript library for manipulating documents based on data.
* [Ruby on Rails](http://rubyonrails.org/) - server-side web application framework written in Ruby

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Chris Bradshaw** - *Version 1.0* - [chrisbradshaw](https://github.com/chrisbradshaw)

* **Linda Haviv** - *Version 1.0* - [lindahaviv](https://github.com/LindaHaviv)

* **Matteo Ziff** - *Version 1.0* - [moziff](https://github.com/moziff)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details