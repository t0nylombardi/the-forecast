# The Forecast

Ruby on Rails weather dashboard for the coding assignment. The app accepts an
address or ZIP-code search, extracts the canonical US ZIP code, retrieves the
current forecast plus a 7-day high/low outlook, and caches normalized forecast
details for 30 minutes by ZIP code.

## Requirements Covered

- Rails application with a browser UI.
- Address input in the sidebar search. The submitted address must include a
  5-digit ZIP or ZIP+4 so the app can honor the cache-by-ZIP requirement.
- OpenWeather ZIP geocoding plus One Call forecast retrieval.
- Current temperature, current conditions, and daily high/low forecast display.
- `Rails.cache` forecast caching for 30 minutes by canonical 5-digit ZIP.
- Visible `Loaded from cache` indicator when a forecast comes from cache.
- RSpec coverage for request, service, presenter, and ViewComponent behavior.

## Setup

```sh
bundle install
pnpm install
```

Configure an OpenWeather API key with either Rails credentials
`weather_api_key` or the `WEATHER_API_KEY` environment variable.

```sh
bin/rails credentials:edit
```

## Run Locally

```sh
bin/dev
```

The development Procfile runs Rails, Tailwind, and esbuild watchers.

## Test And CI

```sh
pnpm build
pnpm build:css
bundle exec rspec
```

The full local CI script is:

```sh
bin/ci
```

## Object Decomposition

- `ForecastsController` handles routing, input selection, status codes, and
  flash/alert rendering.
- `Weather::AddressParser` extracts a canonical 5-digit ZIP from address text.
- `Weather::ForecastService` orchestrates cache lookup, geocoding, API fetch,
  normalization, and failure translation.
- `Weather::CacheRepository` owns cache key construction, 30-minute TTL, and
  cache-hit metadata.
- `Weather::Geocoder` and endpoint clients isolate OpenWeather integration.
- `Weather::ForecastNormalizer` shields the app from vendor response shape.
- `ForecastDashboardPresenter` converts normalized forecast data into the view
  model consumed by ViewComponents.

## Design And Scalability Notes

The app uses service objects around external boundaries and a presenter around
display shaping so controllers stay thin and vendor-specific payloads do not
leak into views. Forecasts are cached after normalization, which reduces API
calls and keeps repeated requests fast. Cache key generation is centralized so
future changes such as multi-country support, cache versioning, or a distributed
cache store can be made in one place.
