# Weather Services

This directory contains the application-facing weather domain services.

The intent of this layer is to keep controller code thin, isolate OpenWeather
integration details, and provide a stable internal contract that the rest of
the application can depend on without coupling itself to third-party payload
shapes.

## Design Intent

- `ForecastService` is the orchestration entry point for the forecast lookup
  use case.
- `Geocoder` is responsible for resolving a US ZIP code into normalized
  coordinate data.
- `GeocoderClient` and `ForecastClient` are endpoint-specific clients built on
  top of `ApiClient`, which centralizes shared HTTP and error-handling behavior.
- `ForecastNormalizer` converts OpenWeather's raw forecast response into the
  application's stable data contract.
- `CacheRepository` stores and retrieves normalized forecast payloads by ZIP
  code so repeated requests can avoid unnecessary external API calls.

## Request Flow

1. A caller invokes `Weather::ForecastService.call(postal_code: ...)`.
2. The service checks the cache for an existing normalized forecast.
3. On a cache miss, the service asks `Weather::Geocoder` to resolve the ZIP
   code into coordinates.
4. `Weather::Geocoder` delegates the HTTP call to `Weather::GeocoderClient`.
5. The service asks `Weather::ForecastClient` for the raw One Call forecast
   using the resolved coordinates.
6. `Weather::ForecastNormalizer` transforms the raw OpenWeather payload into
   the app's normalized response shape.
7. `Weather::CacheRepository` persists the normalized payload and returns the
   wrapped cache response.

## Architectural Boundaries

- Controllers should call `ForecastService` and should not know about
  OpenWeather endpoints, query formats, or response parsing.
- Client classes should only be responsible for talking to external APIs and
  handling transport-level concerns.
- Domain-level normalization should happen after the API call and before data is
  exposed to the rest of the application.
- Cache behavior should remain encapsulated in `CacheRepository` so cache key
  strategy and payload metadata can evolve independently.

## Output Contract

The normalized forecast payload intentionally differs from the raw OpenWeather
response. Consumers inside the application should depend on the normalized
shape produced by `ForecastNormalizer` and wrapped by `CacheRepository`, not on
the vendor response body.

That separation allows OpenWeather-specific changes to be handled in one place
without forcing view, controller, or other application changes throughout the
codebase.
