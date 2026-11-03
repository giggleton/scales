# Scales

R's [scales](https://scales.r-lib.org/) package for Elixir: the pieces a chart's scales are built
from, as plain functions of values, for any charting tool.

Scales finds an axis's breaks and minor breaks, writes their labels, transforms data (logarithms,
square roots, probabilities, dates and times, and your own), maps values to colours, shapes and
sizes through palettes, and rescales or squishes values outside a range. Each function gives the
answer R's scales 1.4.0 gives, to the last digit; where one departs from R, its documentation says
how and why.

```elixir
range = Scales.DataRange.train_continuous(:none, [12.0, 31.5, 18.25, nil])
#=> {12.0, 31.5}
Scales.Breaks.extended(range)
#=> [10.0, 15.0, 20.0, 25.0, 30.0]
Scales.Labels.comma([10.0, 15.0, 20.0], suffix: " km")
#=> ["10 km", "15 km", "20 km"]
```

## Installation

```elixir
def deps do
  [{:scales, "~> 0.1"}]
end
```

## Documentation

The `Scales` module documentation lists the families, each R's family of functions, and the
conventions they share: how a missing value, an infinity and a colour are written.

## Licence

MIT; see [LICENSE](LICENSE). The palettes' colours come from ColorBrewer and viridisLite, listed
with their licences in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
