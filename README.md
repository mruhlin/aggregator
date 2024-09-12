# Aggregator
This is a simple Sinatra app that serves a JSON API tracking readings from devices.  It responds to the following API endpoints:

## Installation
### Prerequisits
This project assumes your system already has the following:
- ruby version 3.2.2
- [RVM](https://rvm.io/) to manage ruby verisons
- `bundler` to install gems

### Setup steps
- Run `rvm use` to set up the correct version of ruby and gemset.
- Run `bundle install` to install dependencies
- Run the server:  `ruby ./server.rb`

By default the server will be running on http://localhost:4567

## Endpoints
The following endpoints are provided:

### POST `/readings`
Logs a set of readings from one device.  POST body should be a JSON object containing the following properties:
- `id` : The ID of the device these readings came from.  Can be any string.
- `readings` : an array of reading objects.   
- `readings[].timestamp` : An ISO-8601 timestamp specifying when the readings were taken
- `readings[].count` : The measured count at the time the readings were taken

Should return `200` and a body like `{"status": "ok"}` if successful, or an error if not successful.

Example: 
```json
{
  "id": "abc123", 
  "readings": [
    {
      "timestamp": "2024-01-01T00:00:00", 
      "count": 2
    },
    {
      "timestamp": "2024-01-02T00:00:00", 
      "count": 7
    }
  ]
}
```

### GET `/:device_id/latest`
The latest timestamp for a given device.  

Accepts the following params:
- `device_id` : The ID of the device whose readings you want

Returns a JSON payload containing the following properties:
- `latest_timestamp` : The timestamp as an ISO 8601 string

Example: 
```json
{"latest_timestamp": "2024-01-01T00:00:00+00:00"}
```

### GET `/:device_id/cumulative_count`
The cumulative total of all counts from a given device. 

Accepts the following params:
- `device_id` : The ID of the device whose readings you want

Returns a JSON payload containing the following properties:
- `cumulative_count` : The total, as an integer

## Error Handling
If any error occurs, the server will return a non-`200` error code along with a body detailing the error.  Check the `message` property for details on what went wrong.

Example: `{"status": "error", "message": "No readings found"}`

## Development
Development in this project is simple.  Most of the work is done by the `Aggregator` class in `lib/aggregator.rb` and the sinatra server in `server.rb`.  Developers who would like to contribute should start there.

## Tests
This project uses rspec.  Tests are stored in the `spec` directory.  Once the code is checked out, tests can be run via the `bundle exec rspec` command.  

## Design Decisions
### Sinatra vs. Rails
I used Sinatra for this project because it's easier to get a bare-bones HTTP API up and running with less boilerplate.  For a more complex project, the investment to build a Rails app would probably pay off, but for a 2 hour project, a smaller deliverable is preferred.

### Error Handling
In a realistic scenario, I might have spent more effort to return more specific error codes in a variety of error conditions.  Ultimately `400 - Bad Request` plus an exception message is good enough for most use cases.  `500 - Internal Server Error` is good enough for situations where I broke.

In a production app we'd also have to take caution about exposing arbitrary exception messages to the user, as they might contain sensitive data.

### API Design
The spec calls for separate endpoints for the latest or the cumulative count.  As those are properties of the same object, it might have made more sense to do a true RESTful approach and have a single endpoint that returns both properties.

If network performance is a concern, we might also consider returning a non-JSON format.  The trade off there is that the API will be less backwards compatible in the future (say, if we decide that the `latest` endpoint should also include the count from that timestamp ).  We could also consider allowing the server to respond in multiple formats based on the HTTP `Accept` header, or typical naming conventions in the path (i.e. `/device_id/latest.json` to get JSON or `/device_id/latest.txt` to get text)


# Future Roadmap
The following points would be good to consider once this MVP is in production.

## Persistence
We want the system to be fault-tolerant, so we should add a persistence layer.  Depending on future requirements we could store the data in a relational database, but the current use case lends itself to a redis server.  We could rewrite the app to use an in-memory Redis instance, then enable persistence on that instance easily enough.

## CI/CD Pipelines
No project should go to production without it.  We should add a CI/CD pipeline and prevent pull requests from merging unless all tests pass with 100% coverage.  Due to time constraints, the project has a representative set of tests and coverage is not considered.

## API Documentation
Given more time, we should use OpenAPI to document the API endpoints instead of just a readme.

## Monitoring
We should add error logging and alerting with something like Rollbar or DataDog.  

## Deployment / Infrastructure
Ideally we want to be able to deploy this to a production environment in a repeatable manner.  Best approach would be to dockerize the app and write helm charts to deploy it to a Kubernetes cluster, and possibly write some Terraform scripts to provision the storage backend, SSL certs, etc.