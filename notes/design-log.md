# scales — Design Notes

The design overview, the decision log and an index of milestones. CLAUDE.md says what applies to
every session; the area files under `.claude/rules/` give each area's invariants and the modules'
documentation how it works; this file says **why** — what was decided and what was rejected — and
indexes what shipped when, each commit's message telling its story. It is reference: read an
entry by name, never the whole file. The `docs-sync` skill routes changes here;
`.claude/rules/docs.md` is the shape.

## 1. What we're building

Scales is R's scales package for Elixir: where an axis's breaks and minor breaks go, how they are
labelled, the transformations a scale holds with their breaks and labels, the palettes that turn
a value's place into a colour, shape, size or line type, values against a range's bounds, the
range of the data a scale has seen, and the colour operations R's palettes are made with. Each
function gives the answer R's scales 1.4.0 gives, to the last digit, and its documentation says
where it departs and why.

It was built inside Giggly (github.com/giggleton/giggly), a grammar of graphics on ggplot2, as
the half of a plot's scales that R keeps in its scales package, then carved out so that any
charting tool can use it and Giggly's growth stops touching it. Giggly, its first consumer, keeps
ggplot2's half: a scale's kind, its defaults, its training and its mapping. Scales never depends
on it. The decisions made while the package lived in Giggly about how the package behaves are in
§4 below; those about how Giggly uses it, and how it was carved out, stay in Giggly's design log.

## 2. Architecture & principles

- **Plain functions of values**: a list where R takes a vector, a keyword list of R's arguments
  checked by NimbleOptions, R's doubles held as R holds them (`t:Scales.double/0`). No process,
  config, clock or IO; the palettes are read when the package compiles.
- **R's answer, to the last digit**, from R's documented methods and the formulas its help pages
  give, never a translation of R's or C's source; where only a port would reproduce R's last bit,
  the departure is measured and stated.
- **Expected values are R's own output** (§5).

## 3. Module map

`Scales` is the root and the one boundary; its moduledoc's table names the module for each of R's
families. `mix boundary.spec` prints the current graph.

## 4. Key design decisions (the "why", so we don't relitigate)

Each entry: **the decision (date, whose call)**, then *Rejected: the alternative* — and why. Newest
first. A decision belongs here when someone could plausibly propose undoing it; the entry is what
stops the question being reopened from scratch. A new entry is about 150 words: the decision, a
sentence or two of why, and one line per rejected alternative. What a later decision replaces is
deleted from the entry it was in, never marked superseded; git history keeps every version.

- **`Transform.data_breaks/3` gives a transformation's breaks in data units, `breaks/3`'s
  before they are transformed (2026-11-07, Steve: "that's fine", then "a", for Giggly's binned
  scales; checked against scales 1.4.0).** R's `transformation$breaks()` finds them on the
  extent turned back, and ggplot2's binned scale compares and widens them there; turned back,
  `breaks/3`'s move in their last digits (sqrt on 5 to 40: 40.00000000000001), so a break R
  holds exactly would drift. It takes `breaks/3`'s arguments, the extent in transformed space,
  so each transformation keeps its own handling of an end that turns back to no number; every
  transformation of numbers has it, and `breaks/3` is it transformed, but for a span of time,
  found in seconds, and a composition, whose first part decides; a date's, date-time's or time's
  raises. In 0.2.0. *Rejected: R's shape, limits in data units*: each caller turns its limits
  back and handles the ends. *Rejected: a `units:` option on `breaks/3`*: a return an option
  chooses. *Rejected: Giggly choosing each transformation's breaker*: this knowledge twice.
- **A logarithmic axis's minor breaks come with R's `detail` beside each value, from
  `MinorBreaks.log_detailed/2` (2026-11-04, Steve: "Yes", for Giggly's `guide_axis_logticks()`;
  checked against scales 1.4.0).** It gives `log/2`'s values in R's order, each `{value, 10 | 5 |
  1}`, R's attribute `rep(c(10, 5, 1), lengths)`: a power of ten (and 0, among limits reaching 0
  or below), five times one, any other multiple. `log/2` is rebuilt on it, so which ladder a value
  came from has one home. In 0.2.0. *Rejected: a caller sorting `log/2`'s values by calling it
  again with `detail: 10` and `5`*: it leans on powers bit-equal across calls, which nothing
  promises. *Rejected: a `tagged:` option on `log/2`, or the pairs from `log/2` itself*: a return
  type an option chooses, and `log/2` would stop serving as a scale's minor breaks.
- **The package was complete when it was carved out of Giggly (2026-11-02, Steve: "Agree").**
  Checked against all 213 exports of scales 1.4.0's NAMESPACE: every current one built,
  superseded, or left out by an increment's agreed list; the 2026-10-27 not-wanted list confirmed
  (`demo_*`, `show_col`, `label_math`/`label_parse`, `label_glue`, `number_options`, R's R6
  `Range` classes, `ordinal_french`/`_spanish`). `colour_ramp()` is covered by `{:gradient,
  colours}`, which has no `na.color`; `cscale()` and `dscale()` are left out, the root's example
  showing their steps. *Rejected: adding `cscale()` and `dscale()`*: two calls that only chain
  functions the package exports.
- **The repository starts with one import commit naming the Giggly commit it was taken from
  (2026-11-02, Steve: "A").** The history before it lives in Giggly's public repository, whose
  `git log` and blame keep it, the code under `lib/giggly/…` before the split of 2026-10-27, as
  Pica started fresh. *Rejected: `git filter-repo`* keeping the package's paths and their
  pre-split paths: 63 and more commits whose messages describe Giggly changes the filtered diffs
  no longer hold, and the earlier paths mapped by hand.
- **The harness is Giggly's, copied, less what is Giggly's own (2026-11-02, Steve: "Yes").** Both
  hooks, the review, docs, dependency, timing and mutation skills, `dev/` and `test/tack/` from
  Tack `9ae74d8`, `.credo.exs` with `ZipMap` and `PassTimeZoneDatabase`, and CI, as Pica's was
  copied from Giggly's (its `aaf3412`); left behind: the check that a plot runs nothing, the
  review's stats-through-the-frame check, and the build without Pica. *Rejected: a fresh `mix
  tack.install`*: the gaps in Tack's templates that Giggly's copies fixed. *Rejected: a gate
  alone*: the package checked less than it was inside Giggly.
- **A decision about the package's behaviour moved here; one about how Giggly uses it stayed
  (2026-11-02, Steve: "Yes").** Each entry moved word for word and was deleted from Giggly's log,
  judged one by one; the carve-out's own entries stayed, as Giggly's history, and Giggly's §6
  lines with them. A citation of an entry that stayed says "Giggly's design log". *Rejected:
  every shared entry in both logs*: a decision with two homes, one edit leaving the other wrong.
  *Rejected: everything left in Giggly's*: the package's decisions unreadable from its own
  repository.
- **The package keeps `use Boundary`, and its one boundary exports every module (2026-11-02,
  Steve: "Yes"; `exports: :all` 2026-11-03, Steve: "Yes", released in 0.2.0).** `{:boundary,
  "~> 0.11", runtime: false}` is compiled by a user's project, never started and out of a
  release, with no dependencies of its own; Giggly and Pica list it already. It holds the
  package's own calls out to its `deps:`. Boundary also holds a caller that runs it to a
  dependency's exports, and a library marks what is API by its documentation, `@moduledoc false`
  and private functions, not by policing its callers; 0.1.0's list of six left out the
  documented `Scales.Breaks`, so a caller's boundaries refused calls its documentation offered, a
  bug, a patch on its own, released in 0.2.0 beside `format/2` (the entry beginning
  "`Scales.Labels.format/2` is R's `format()`"). *Rejected: dropping the declarations*: the same to callers, but the
  package's own `deps:` unchecked. *Rejected: adding `Breaks` and `MinorBreaks` to the list*: it
  fixes today's call and keeps a second statement of the API that can drift from the first.
- **`Scales.Labels.format/2` is R's `format()` of a numeric vector, public, and with it the
  package is 0.2.0 (2026-11-03, Steve: "just make the scales function public").** Giggly's filled
  contours label their bands as ggplot2 does, `format(digits = 3, trim = TRUE)`, which the
  labellers already reach through the internal `Scales.Labels.Format`; `format/2` hands it R's
  `digits`, `nsmall`, `scientific`, `big.mark`, `decimal.mark` and `trim`, a missing number `NA`
  as R writes it. A new public function is a minor version. *Rejected: Giggly building it from
  `number/2` and `scientific/2` and R's width rule*, a second home for that rule. *Rejected:
  Giggly calling `Scales.Labels.Format`*, an internal module whose shape is the package's own.
- **The package's metadata (2026-11-02, Steve: "Yes").** `:scales` 0.1.0, `elixir: "~> 1.20"`,
  `giggleton/scales`, MIT; `THIRD_PARTY_NOTICES.md` carries ColorBrewer's copyright with Apache
  2.0's text and viridisLite's MIT notice, since the palettes ship in `priv/`; `color` pinned to
  `~> 0.13.0`, a 0.x minor being free to break. The name was free on Hex. *Rejected: crediting
  R's scales authors in the licence*: no R source was translated; the documentation credits scales
  as the model.
- **Mutation testing came with the package, without a pass over the whole of it (2026-11-02,
  Steve: "Bring it over but don't do the full repo pass that will lock up my computer for a
  day").** The skill, its warm runner and the commit gate's rule, `muex` pinned; the import, a
  root commit, needs no pass of its own, as the gate already holds. So whether the package's
  tests alone kill its mutants, where Giggly's ran beside them on every earlier pass, is open
  (§7). *Rejected: leaving it behind, as Pica did*: every later change unmeasured.
- **The carve-out goes in one order, each step leaving the machine on Steve's word (2026-11-02,
  Steve: "A").** Giggly's `main` pushed, its CI green, and the import naming that tip; the package
  built and gated here, then tried under Giggly in a scratch worktree with a path dependency;
  `giggleton/scales` created and pushed, its CI green; the package published; then Giggly takes
  it from Hex and deletes its copy. *Rejected: publishing before Giggly's push*: the import and
  the package's links naming a commit GitHub lacked. *Rejected: no trial*: a break found after
  0.1.0, fixed by a 0.1.1.

- **The platform's asinh, atanh, erf and erfc stay, and a figure resting on them is pinned as
  R's within the rules' bounds, never as one C library's double (2026-11-02, Steve: "Just use
  :math and accept the difference"; checked on glibc 2.39 and 2.43).** CI's move to Ubuntu 26.04
  failed three transform tests that pinned glibc 2.39's doubles. R's own asinh and atanh move with
  the C library (2.43 gives the correctly rounded `atanh(0.5)`, 2.39 a double below), so the
  package's may; R's `pnorm()` is its own and does not, while the package's goes through
  `:math.erfc`, and 2.43 moves `pnorm(0.5, 1, 2)` a double below R's, within the distribution's
  3. *Rejected: an error function of the package's own* (Cody's 1969 rational approximations):
  new numerics to hold a bound already met. *Rejected: CI pinned to Ubuntu 24.04*: the suite
  would pass only on one C library, and its "departures" were that library's.

- **A quotient past about 4.5e15 is tested for multiples of 10 by its exact remainder, a stated
  departure from R (2026-11-02, Steve: "A"; checked against scales 1.4.0 on R 4.6.1, x86_64).**
  `precision()` asks whether every `round(x / precision) %% 10` is 0; past `1 / eps` R's `%%`
  (`myfmod()`) warns "probable complete loss of accuracy in modulus" and gives its long double's
  remainder, so `comma(c(10, 5.71e305, 5, 1, -1.1e307))` takes accuracy 1 in R and 0.1 here, and
  5.71e305's label is written from another double (3 of 2,000 random huge-beside-small cases).
  R's answer there is its platform's long double's, 80 bits on x86 and others elsewhere, and an
  axis's evenly spaced breaks never reach it. *Rejected: x87's 80-bit rounding emulated in
  integers*: new numerics for a value R calls lost, matching one of R's platforms, near a port
  of C's steps.

- **A range is widened by `Scales.Bounds.expand_range/2`, R's `expand_range()`, and Giggly's
  extents through it (2026-11-02, Steve: "A" twice, increment 4's step 10; checked against
  scales 1.4.0).** `mult:`, `add:` and `zero_width:`, R's `mul`, `add` and `zero_width` with
  their defaults 0, 0 and 1, checked by NimbleOptions, `mult:` and `add:` a number or
  `{low_end, high_end}`, R's vector of two, which ggplot2's `expand_range4()` hands it; `mult:`
  is the name Giggly's `expand:` gives the same amount. Ends are R's doubles through
  `Scales.Double`: an infinite end widens to the infinities, and with no multiple gives `:nan`
  at both, R's `Inf * 0`; a `nil` or NaN end is refused, as R fails; an infinite or missing
  amount is refused, where R takes it. The scales 1.4.0 export the 2026-10-27 gap list missed,
  counting Giggly's own expansion as the package's. *Rejected: R's `mul:`*, an abbreviation
  neither library uses. *Rejected: positional amounts*, where every `Scales` function takes
  keywords. *Rejected: refusing infinite ends*, which every other `Bounds` function takes.
  *Rejected: `Inf * 0` as 0*, tidier and not R's.

- **A transformation of your own labels its breaks turned back rounded to 14 significant digits
  unless it says (2026-11-02, Steve: "A", increment 4's step 8; checked against ggplot2 4.0.3).**
  `Transform.new/2` without `labels:` records `&Labels.plain_round_tripped/1`, as logit's and
  exp's labels are written: a cube of one's own on 1 to 10,000 turns its breaks back as
  2499.999999999999 to 9999.999999999995, in R as here, which R's `format()` writes `2500` to
  `10000` at 7 digits and `plain/1` at 15 `2500.00000000000` to `9999.99999999999`. An inverse a
  user writes, a power or a root, rarely gives a break back exactly, and 14 digits lose a label
  only on axes ending within 5e-12 of 1 (the entry beginning "A break turned back"). *Rejected:
  plain labels, as step 6 had them*: noise on 46 of the 552 rows of step 8's table, R's labels
  on none.

- **A composition is the name `{:compose, [part, ...]}` (2026-11-01, Steve: "A", increment 4's
  step 6's C1; checked against scales 1.4.0).** R's `transform_compose("log10", "reverse")`, or
  `transform = c("log10", "reverse")`, is `{:compose, [:log10, :reverse]}`, resolved as every
  name is, each part a name, a user's own transformation or another composition, so a
  composition of built-ins stays a value that compares and prints. One part is allowed, as R's;
  none is refused. *Rejected: a bare list, R's `c()`*: the one compound name without a tag, and
  `[]` and one part would need rules of their own. *Rejected: `Transform.compose/1` returning a
  value of functions*, as R's returns a `new_transform()`: built-ins would stop being names.

- **A composition's breaks are its first part's, `n:` reaching them, and its minor breaks R's
  regular ones unreversed (2026-11-01, Steve: "A", "A", increment 4's step 6's C6 and C8;
  checked against ggplot2 4.0.3).** As R's, the extent is turned back through the later parts
  into the first part's space and broken there by that part, so its rules hold: an exponential's
  or Yeo-Johnson's end past its bound is set aside (exp then reverse on 0 to 5 draws R's five
  stacked breaks). R calls the first part's breaks without `n`, and ggplot2 warns "Ignoring
  `n.breaks`"; here `n:` is handed on, so log10 then reverse with `n: 2` draws log10's one
  break, and a first part refusing it (time, a span of time) refuses it here; a user's breaks
  function of two arguments is handed it, one of one refuses it, as `:time`. Minor breaks are
  R's `regular_minor_breaks()` with `reverse` off, whichever way the composition runs, so log10
  then reverse on 0.01 to 5 draws 1.5 and 0.5 but not -0.5, R's drawing. *Rejected: refusing
  `n:`*: a plot R draws fails. *Rejected: minor breaks reversed when the composition falls*: a
  gridline ggplot2 does not draw.

- **A composition's labels are its first part's (2026-11-01, Steve: "A", increment 4's step 6's
  C5; checked against ggplot2 4.0.3).** R writes every composition's labels with `format()`;
  Giggly replaced `format()` long ago with each transformation's own rule, so here the breaks
  and the extent are turned back through the later parts to the first part's `format/4`: Box-Cox
  in 2 then reverse writes `0.000 0.002 0.004 0.006` from data units as R does, a date first
  writes its dates, and a span of minutes then reverse `20m`, as R's timespan alone writes it,
  where R's composition writes `20 mins`. A later part with an inexact inverse leaves its round
  trip, as R's does under `format()`'s seven digits: log10 then sqrt labels 1000 as
  `999.999999999999`; re-finding the first part's breaks to hand it exactly, as Box-Cox's labels
  do, is left until a composition needs it. *Rejected: plain labels from the round trip*:
  `0.002000000000001` under Box-Cox, and a date first unlabelled.

- **A composition's domain is R's, but the range's two ends are ordered as a pair (2026-11-01,
  Steve: "A", increment 4's step 6's C4; checked against scales 1.4.0).** As R's: the first
  part's domain transformed, cut to each later part's domain and transformed again, turned back
  through every inverse and sorted, `ArgumentError` when nothing is left (sqrt, reverse, log10),
  as R aborts; so sqrt then log10 takes 1e-200 up and exp then log -230.26 up. R takes `min()`
  and `max()` of the range alone, each keeping the first of an equal pair, so the reciprocal's -0
  and +0 both come out -0 and the reciprocal then reverse has the domain `-Inf, -Inf`, its
  `trim_to_domain()` of -5 to 1000 `0, 0`; no drawing shows it, ggplot2 squishing nothing into a
  domain of no width. Here the pair's first is low and second high, so the domain is the
  reciprocal's own line and the trim `-0.001, 0.2`; every other tie is R's, matched over 2,740
  rows of composed pairs and triples. *Rejected: R's exactly*: a package function's wrong
  answer copied for no drawing. *Rejected: -0 below +0 everywhere*, as first built: R's
  `0 <= -0` holds, so sqrt, reverse, sqrt, R's domain 0 to 0, came out empty.

- **A date, date-time or time transformation comes first in a composition, or nowhere
  (2026-11-01, Steve: "A", increment 4's step 6's C7; checked against ggplot2 4.0.3).**
  `scale_y_date()` takes no `transform`, so R's reversed date axis is
  `scale_y_continuous(transform = c("date", "reverse"))`, and ggplot2 draws date, date-time and
  `hms` then reverse with the first part's labels; the composition here takes and gives the
  first part's values, its breaks and labels, and `width/3` lays steps through it (two weeks: R's
  full dates from 2024-01-08), with no derivatives and no `trim_to_domain/2`, never squished. A
  temporal part elsewhere raises `ArgumentError`, as R's reverse then date-time fails to build
  (its `hms` is a number, ours a `Time`). *Rejected: compositions of numbers only*: a reversed
  date axis in Giggly would reopen scales for a release.

- **`Transform.new/2` takes a name and keyword functions, checked at the call (2026-11-01,
  Steve: "A", increment 4's step 6's C2; checked against scales 1.4.0).**
  `Transform.new("cube", transform: f, inverse: g, ...)`: the name a string, as R's
  `new_transform()` requires one, read by messages and `inspect`; `derivative:`,
  `inverse_derivative:`, `domain:` (the line unless given), `breaks:` (limits in data units),
  `minor_breaks:` (breaks and extent in transformed space) and `labels:` (breaks in data units)
  optional, R's defaults but the labels' (the entry beginning "A transformation of your own
  labels"); a `%Scales.Transform{}` comes back. NimbleOptions refuses a missing
  function, an unknown option, another arity and a domain not low to high, where R checks
  nothing and fails when an axis first calls it, or keeps `c(Inf, 0)` backwards. *Rejected: no
  name, `new(&cube/1, inverse: ...)`*: messages would say "a user's transformation", and the
  required inverse would be an option.

- **A transformation of your own is handed every value in its domain, its ends among them
  (2026-11-01, Steve: "A", increment 4's step 6's C3; checked against scales 1.4.0).** R's help
  says the function "is expected to be able to transform the `domain` argument", and ggplot2
  transforms the domain's ends on every axis, so on the default line a user's function is
  handed `:neg_infinity` and `:infinity`, and an annotation at `Inf` one too: Erlang's arithmetic
  raises on them where R's IEEE arithmetic gives the cube of `Inf` as `Inf`, so a function on an
  unbounded domain writes a clause for each, the moduledoc showing how. An integer is handed as
  a float; `nil` and `:nan` are kept uncalled; a value outside the domain is `:nan` uncalled, a
  departure (R's cube with a domain from 0 gives -8 for -2), so `&:math.sqrt/1` on a domain from
  0 never meets a negative. It returns a number, an infinity, `:nan` or `nil`; anything else
  raises `ArgumentError` naming it. *Rejected: finite floats only*: a falling function's `Inf`
  drawn on the wrong edge, a bounded one never squished, its inverse handed 1.05.

- **Box-Cox, modulus, Yeo-Johnson and a span of time are `{:boxcox, exponent}`, `{:modulus,
  exponent}`, `{:yj, exponent}` and `{:timespan, unit}`, a modulus offset from 1 (2026-11-01,
  Steve: "A", "A", increment 4's step 5; checked against scales 1.4.0).** The exponent, R's
  required `p`, goes first as `{:log, base}`'s base does, an optional offset as a keyword,
  `{:boxcox, 0.5, offset: 3}`, as `{:probability, :normal, mean: 1}` holds its options; `:yj`
  keeps R's name, as `:asn` did; `:timespan` is seconds, its unit `:second` to `:week`,
  `Breaks.timespan/2`'s names. The exponent is any number, a Box-Cox offset one from 0 up, R's
  documented range, and a modulus offset one from 1 up: below 1 R's modulus no longer rises,
  offset 0 sending 0.5 to -0.586 and -0.5 to +0.586. Anything else raises by guard.
  *Rejected: `{:yeo_johnson, ...}`*: the house rule over R's name, where `:asn` kept R's.
  *Rejected: keywords throughout*: an exponent no keyword can leave out. *Rejected: R's
  documented offset from 0 for the modulus*: points near zero drawn out of order. *Rejected: R's
  acceptance*: a negative offset, falling or folding through the squish and the breaks.

- **The Box-Cox, modulus and Yeo-Johnson transformations are their documented formulas, R's
  doubles but the platform's last bit (2026-11-01, Steve: "A", increment 4's step 5; checked
  against R 4.6.1).** Each is `(base^exponent - 1) / exponent` as scales' help pages write it,
  evaluated with R's `^` (`Double.power/2`: a square `x * x`, 1 and 0 deciding first), an
  exponent within 1e-7 of 0 its logarithm, as R's. On 3,000 random doubles every value and
  derivative was R's but where Erlang's power parts from R's x86 `powl` (Box-Cox in 3 on 65, up
  to 42 ulps near 1 where the subtraction amplifies it; ours the right one 57 times, R's 19) and
  log1p's and expm1's methods (a double). Near 0 both lose every digit, yj(0.5) of 1e-16 being 0.
  yj's inverse derivative below 0 at an exponent of 2 is the slope `exp(-x)`, where R's fails (Q4).
  *Rejected: an expm1/log1p form*, within 1e-13 of the truth everywhere: half of R's doubles moved
  by a few ulps for precision no plot shows.

- **Box-Cox's domain is R's, from 0 whatever the offset, and a value below minus its offset NaN
  (2026-11-01, Steve: "A", "A", increment 4's step 5; checked against scales 1.4.0).** R refuses
  the whole vector when any value is below minus the offset; here that value alone is NaN, as a
  logarithm's negative is, so a plot draws the rest. R's domain is `c(0, Inf)` whatever the
  offset, so with offset 3 on data from -2.9 to 1 ggplot2 finds breaks 0, 0.5 and 1 only, the
  values from -3 to 0 still transformed; Giggly draws that axis, as the rule of copying R's odd
  but unbroken drawings says. *Rejected: R's raise*: one stray value fails the plot, the only
  transformation raising on data. *Rejected: the domain from minus the offset*: breaks -2 to 1
  there, a departure for a few breaks on an uncommon axis.

- **An axis past a bound a transformation never reaches is broken on its other end, as R's
  (2026-11-01, Steve: "A", increment 4's step 5; checked against ggplot2 4.0.3).** Box-Cox and
  modulus with a negative exponent and yj below 0 or above 2 bound their values, and the 5%
  widening passes the bound: `Transform.squish/2` now squishes every transformation of numbers
  into its sorted transformed domain, as `get_breaks()` does, so the end sits on the bound, turns
  back to an infinity, and is set aside, as an exponential's NaN end is, R's five copies of the
  other end found: boxcox(-1) on 1 to 100 draws no breaks, yj(-1) on -10 to 10 five stacked at
  its bottom, as ggplot2 does; both ends, none. A third of random axes with a negative exponent.
  *Rejected: no breaks whenever an end turns back*: a second rule, departing under yj(-1).
  *Rejected: raising*: it fails a plot R draws.

- **Box-Cox, modulus and Yeo-Johnson labels are written from their breaks in data units
  (2026-11-01, Steve: "A", increment 4's step 5; checked against scales 1.4.0).** Turned back,
  their breaks lose digits a fixed rounding cannot restore: under boxcox(2) 0.0064 comes back
  0.0063999999999983, under boxcox(3) as few as three digits survive, since the transformed space
  holds no more, and offset 3's 0 comes back -4.4e-16, which R writes `-4.440892e-16`; 14 digits
  left noise on 10-35% of random axes. So `format/4`, handed the extent squished as `breaks/3`
  is, finds the same breaks in data units again and writes each from its own value, the first
  where two share a position; a given break is turned back at 14 digits, and a labels function
  handed the round trip, as R hands it. *Rejected: the rule for every inexact inverse*: steps 3's
  and 4's built code reopened. *Rejected: 14 digits, as theirs*: the noise.

- **A plain label past what Erlang writes is written whole, as R writes it (2026-11-01, Steve:
  "A", increment 4's step 5's C8; checked against R 4.6.1).** `Labels.plain/1` raised
  `ArgumentError` on a break above about 1e255 or below about 1e-253, where
  `float_to_binary/2` refuses more than 256 characters or 253 decimals, so a log10 axis reaching
  1e256 failed its plot. There it now writes the double's exact digits, `Labels.Format`'s
  `sprintf()` rule, as R's `format(scientific = FALSE)` does: 2e257 in R's 258 characters,
  10^308 in 309; every smaller label is unchanged, 1e23 still R's `99999999999999991611392`.
  *Rejected: scientific notation past some size*, as R's default `format()` writes `1e+23`:
  plain's rule is never scientific, and 1e23's label would change too. *Rejected: the fix inside
  step 5's commit*: an unrelated fix mixed into the transformations.

- **A distribution's spread is above 0 and its location a number, and the normal quantile's
  middle is bisected on `erf` (2026-11-01, Steve: "A", "A", increment 4's step 4, "Ok" for the
  quartiles; checked against scales 1.4.0).** `{:probability, :normal, mean:, sd:}` and `{:probability, :logistic,
  location:, scale:}` take either keyword or both, R's defaults 0 and 1, `:probit` and `:logit`
  their standard forms; any other value is refused by guard, as a base is. The quantile bisected
  on the distribution was 25% off at p = 0.5 + 1 ulp, many quantiles sharing one distribution
  double there: between 0.25 and 0.75 it is bisected on `erf(q / sqrt(2)) / 2` against `p - 0.5`,
  exact there, the quartiles themselves on the distribution, which gives them correctly
  rounded, as R's, where `erf` is a double off; within 5 ulps of R's, correctly rounded on 86% of 3,000 where R's is on 31%; the
  density splits `x * x` exactly first (Dekker), within 7 ulps of R's, nearer the truth where
  they part. *Rejected: R's positional parameters*: sd alone would spell out the mean.
  *Rejected: R's spread of 0*: every value at the mean. *Rejected: Wichura's AS241*: 50 typed
  coefficients, R's tails since changed, and R's quantile is the less accurate.

- **A break turned back through an inexact inverse is written to 14 significant digits
  (2026-11-01, Steve: "A", "A", increment 4's step 3; checked against scales 1.4.0).** Every
  transformation keeps plain labels (the 2026-10-12 rule, so a natural log's powers of e take 15
  digits where R's `format()` gives 7), but log1p's, exp's, asinh's, the pseudo-logarithm's and,
  from step 4, logit's, probit's and both probability tuples', and from step 8 a user's own by
  default, labels are written from each break
  turned back rounded to 14 significant digits first (`Labels.plain_round_tripped/1`): the round
  trip leaves `10000` as `9999.999999999989` under a pseudo-logarithm in sigma 2, base 10, and
  `0.0009` written `0.000900000000000001` under logit. Against the breaks' own labels in data
  units, at 15 digits up to 40% of random axes showed that error, at 14 none of 28,000, and under
  a probability only axes ending within 5e-12 of 1, whose breaks need 15 digits; asn and atanh
  showed none and stay plain. *Rejected: 14 digits
  in `plain/1` itself*: an identity axis needing 15 (1e14 to 1e14 + 4) would collide.
  *Rejected: R's `format()`*, for these alone or for all: `:log10` and `{:log, 10}` written two
  ways, or the agreed plain labels reopened. *Rejected: plain as it was*: the noise. *Rejected:
  asn and atanh round-tripped too*: their 15-digit axes near 1 lost for nothing.

- **A logarithm's or exponential's base is above 1, a pseudo-logarithm's sigma above 0, and asinh
  and atanh are the platform's (2026-11-01, Steve: "A", "A", "A", increment 4's step 3, and "A",
  step 4; checked against scales 1.4.0).** Names: `:log`, `:log2`, `:log10`, `{:log, base}`, `:log1p`, `:exp`,
  `{:exp, base}`, `:asinh`, `:pseudo_log` and `{:pseudo_log, sigma:, base:}`, either keyword
  optional, R's defaults. Any other base or sigma is refused by guard; a falling axis is the base
  above 1 reversed. asinh is `:math.asinh`, within 1 ulp of R's correctly rounded one (369 of
  3,000 off under glibc 2.39), and atanh `:math.atanh` likewise (368). *Rejected: positional `{:pseudo_log, sigma, base}`*: sigma alone,
  the usual call, would spell out e. *Rejected: R's bases below 1*: `squish/2` and
  `Breaks.log/2` would take a falling domain, for an axis nobody draws. *Rejected: an own
  correctly rounded asinh or atanh*: new numerics for one ulp; *one through log1p*: further off
  (asinh's 540).

- **A NaN is `:nan` throughout `Scales.Bounds`, and a `nil` end bounds nothing, `discard/2`'s
  too (2026-11-01, Steve: "A", "A", increment 4's step 1; checked against scales 1.4.0).**
  Every rescaler and `oob_*` function takes R's doubles (`t:Scales.double/0`), infinite ends
  among them, through an internal `Scales.Double` of IEEE arithmetic: a NaN given or worked out
  (0/0, Inf − Inf, Inf/Inf) is `:nan`, `NA` is `nil`, as in the frame, so `rescale_max()`'s 0
  over a high end of 0 is `:nan`; Giggly's scales map either to `na_value`, as ggplot2's
  `is.na()` does. `discard/2` with a `nil` end bounds nothing on that side, as `censor/2` and
  `squish/2` do. *Rejected: a computed NaN kept `nil`*: R's two answers become one, and the
  package holds two rules. *Rejected: R's `discard()` with an `NA` end*: every value the other end
  keeps comes back `NA`, from R's logical indexing, no rule a caller can use.

- **A transformation gives R's doubles: NaN `:nan`, its derivatives R's at `nil` too, and
  `trim_to_domain/2` of nothing `:none` (2026-11-01, Steve: "A", "A", "A", increment 4's step 2;
  checked against scales 1.4.0).** A value outside the domain transforms to `:nan`, R's NaN, and a
  missing one stays `nil`, as `Scales.Bounds` holds them; Giggly's scales already send either to
  `na_value`. The identity's and reverse's derivatives are R's `rep(1, length(x))` and `-1`
  everywhere, `nil` and `:nan` included. `trim_to_domain/2` follows R (range, squish, ends
  transformed) but gives `:none` with no value to range over. *Rejected: NaN `nil`*: R's two
  answers made one, the package's rule split between Bounds and Transform. *Rejected: `nil` at
  `nil` for the identity's derivatives*: a departure for a value nothing reads differently.
  *Rejected: refusing no values*: every caller would check for empty data first. *Rejected: R's
  transformed `Inf` and `-Inf`*: R's own warning says they mean nothing, and silently they would
  read as a range.

- **The scales package carries every transformation of scales 1.4.0: a user's own holds
  functions, the maths Erlang lacks is the package's own, logit and probit, and derivatives
  (2026-11-01, Steve: "A", "A", "A", "B"; checked against scales 1.4.0).** A user's own is
  `Scales.Transform.new/2`, R's `new_transform()`: functions of one value (`&Mod.fun/1` keeps it
  readable), a domain, breaks handed limits in data units; built-ins stay names. log1p (Goldberg's
  `log(u) * x / (u - 1)`), expm1 (Kahan's), the normal CDF (`erfc` with its argument's rounding
  corrected) and quantile (bisection on it, its middle on `erf`: the entry beginning "A
  distribution's spread") match R to a few ulps.
  `:logit`, `:probit`, and the normal and logistic with R's parameters; other distributions
  through `new/2`. Every numeric transformation has R's derivatives, a composition's by the chain
  rule. *Rejected: a module a user writes*: internal callbacks made API. *Rejected: Nx*: its
  `log1p` is `log(x + 1)`, and `erf_inv(2p − 1)` 6.7e-5 off, `-Inf` below p ≈ 3e-17.
  *Rejected: Cauchy and other closed forms, or R's whole stats list*: kernels nobody asked for.
  *Rejected: derivatives left out*: nothing in ggplot2 reads them, but they are part of R's
  object, and scales should not need reopening for a tool's density.

- **`dictionary/2` matches a value by `Scales.DataRange.key/1`, a map under `dictionary:` (2026-10-31,
  Steve: D1 to D4 "A"; checked against scales 1.4.0).** `dictionary(breaks, dictionary: %{value =>
  label}, nomatch:)`, the family's shape, each label a string or `nil`. A key names what a
  discrete scale's map of labels names, so `2` names `2.0` and `"1"` never the number 1, where
  R's `match()` compares text. `nomatch:` is `:none` unless given: an unmatched string is its own
  label and `nil` stays missing, as in R, and any other value raises, which R hands back as
  `as.character()`; a string or `nil` replaces every unmatched value, `nil` included. Refused: a
  key `nil`, which never matches; two keys sharing a key (`1`, `1.0`), as `Plot` refuses a value
  named twice; a `nomatch:` but a string or `nil`. A `""` key is taken, which R refuses only as a
  vector's unnamed element. *Rejected: string keys alone* — useless on a discrete axis of
  numbers. *Rejected: R's text for a value* — `as.character()` in the package (below). *Rejected:
  a list of pairs, first winning* — a shape no other labels option takes, its repeats mistakes.

- **`wrap/2` takes a width, a positive integer, and strings and `nil` alone (2026-10-31, Steve: W2
  "A", W3 "A"; checked against scales 1.4.0).** `width:` is required, as R's `label_wrap()`
  requires it, and checked by NimbleOptions; R lays a word while the line and one more character
  fit within it, which for a whole width is "shorter than the width". `nil` is written `"NA"`
  (the entry beginning "A missing break's label"); anything but a string, and text that is not
  valid UTF-8, raises. *Rejected: any number, R's rule exactly* — a fraction is a threshold no one
  means, zero and below repeat 1, `Inf` wraps nothing. *Rejected: 25 unless given* — ggplot2's
  facet default, not scales'; the facet keeps it. *Rejected: numbers and booleans written as R's
  `as.character()`* — a second home for `Giggly.AsCharacter`'s rule, which the entry beginning
  "`ordinal/2`'s rules are matched" refused. *Rejected: `to_string/1`* — `1.0e5` and `true`,
  departing from R unannounced.

- **`wrap/2` counts a character as R 4.6.1 does, from R's own measured widths (2026-10-31, Steve:
  W1 "B"; checked on every code point).** `nchar(intToUtf8(code_point), type = "w")` under
  `en_US.UTF-8` in the image, for every code point, gives 457 runs not of width 1 (116 wide, 341
  zero), held as a literal in the internal `Scales.Labels.Width` and summed per code point as R
  sums them: CJK, fullwidth and most emoji 2, combining marks, zero-width spaces and joiners 0, a
  joined family emoji 6, and a word of zero-width characters alone dropped as whitespace, as R
  drops it. In a Chinese, Japanese or Korean locale R counts an ambiguous character as 2; this is
  its default column. *Rejected: graphemes* — the facet's earlier call, made for a private helper
  against a dependency; the package's labels are R's to the character. *Rejected: a Hex width
  table* — a dependency, and Unicode's answer rather than R's. *Rejected: a file under `priv/`* —
  a compile-time read under `CorePurity`'s palette waiver.

- **The date labellers write a `Date` at midnight UTC and a `NaiveDateTime` as UTC, each takes
  its own kinds, and `tz:` is any zone its database reads (2026-10-31, Steve: "A" on each of three
  calls; checked against scales 1.4.0).** R writes a `Date` at midnight UTC whatever `tz` says
  (`%H` `00`, `%Z` `UTC`), where `Calendar.strftime/3` raises on `%H` and writes `%Z` empty, so a
  `Date` and a `NaiveDateTime` are written as UTC `DateTime`s, never shifted. `date/2` and
  `date_short/2` take dates and date-times, `time/2` date-times and times, as `label_time()`
  refuses a `Date`; R's `label_date()` writes an hms in its own text whatever the format, so a
  `Time` is refused there. Kinds and zones may mix, `date_short/2` dropping the time where every
  value is a `Date` or at its own midnight. `tz:` is `"Etc/UTC"` unless given, checked at the call
  against `time_zone_database:`. `%s` is the instant's Unix time in every zone (Steve: "A"),
  where R's, outside UTC, counts the wall clock as UTC's. *Rejected: Calendar on the structs as
  they are*: `%H` raises. *Rejected: R's `%s`, or refusing `%s` outside UTC*: a count of nothing,
  or a true one refused.
  *Rejected: `date/2` writing times*: two labellers for one thing. *Rejected: `"UTC"` read as
  `"Etc/UTC"`*: a name the database does not know, accepted anyway.

- **`date/2`'s and `time/2`'s `format:` is one string, checked at the call (2026-10-31, Steve:
  "A"; checked against scales 1.4.0).** R recycles a vector of formats over the breaks, an axis
  of mixed labels, and reads `""` as `format()`'s own default; here a format is one string of at
  least one character, written on `~U[1970-01-01 00:00:00Z]` at the call, as `date_labels:` is,
  so one Calendar cannot write raises even for no breaks. A date conversion on a `Time` passes
  that and raises an `ArgumentError` naming the format when written, where R writes 1970-01-01.
  `%%Y` is a literal `%Y`, as in R, which `DateBreaks.label/2` had replaced with the year.
  *Rejected: `""` as R's default*: the default is already R's.

- **`date_short/2` takes its parts by name and writes each on its own (2026-10-31, Steve: "A" on
  each of three calls; checked against scales 1.4.0).** `format:` is `[year:, month:, day:,
  time:]`, a part left out R's default and `nil` never written, as R's `NA`; R's vector of four
  errors at three on times and ignores a fifth. `leading:` replaces a `0` at the start of each
  part, as text, before `sep:` joins them; R replaces `^0` and `sep` then `0` in the joined text,
  which differs only under `sep: ""` (every `0`), a part or full label holding `sep` then `0`,
  and a backslash, which R reads as an escape. A break with no part to write is R's `format()`
  default in `tz`, `%Y-%m-%d` where each such break is exactly midnight, else to the second.
  *Rejected: four formats in order*: one changed means four written. *Rejected: R's text
  replacement*: `"2020"` written `"2 2 "`. *Rejected: an empty label*: R names the date.

- **A break whose quotient by the accuracy `precision()` tries passes the largest double is left
  out of its test for multiples (2026-10-31, Steve: "B"; checked against scales 1.4.0).** R's
  `precision()` asks whether every `round(x / precision)` is a multiple of 10; a quotient past
  the largest double is `NA` there, so beside a break that is no multiple R's `all()` is false,
  as here, but beside multiples alone R fails ("missing value where TRUE/FALSE needed"), on
  `number(c(1.5e308, 1, 2))`. Here the others decide, as `precision()` already drops an infinite
  break. Erlang raised on the division before, whichever case. *Rejected: raising where R
  fails*: an axis refused for a test the break takes no part in.

- **`timespan/2` takes `unit:`, `space:` and `number/2`'s options but `scale_cut:`, on numbers
  alone (2026-10-31, Steve: "A"; checked against scales 1.4.0).** `unit:` is `:second` to
  `:week`, `Breaks.timespan/2`'s names, each break times its unit's seconds as R converts a
  `difftime`, then `number()` under `cut_time_scale(space)`; `scale_cut` is R's collision, and a
  break the unit takes past the largest double is `Inf`, as R's is. *Rejected: Elixir's
  `Duration`*, as R takes a `difftime`: its months and years have no length in seconds, and it can
  be added later. *Rejected: R's unit strings (`"secs"`)*: a second set of names in one package.

- **`pvalue/2`'s accuracy is at most 0.5, its `prefix:` three strings, and `add_p: true` beside
  `prefix:` raises (2026-10-31, Steve: "B", "A"; checked against scales 1.4.0).** Above 0.5 a
  p-value is both below the accuracy and above 1 less it, and R writes the second, a false label
  (`accuracy = 1` gives `"<1" ">0" ">0"`); 0 gives `"NA"`, a negative fails, `NULL` is `number()`'s
  plain labels. `prefix:` is `{below, between, above}`; R lets `prefix` silently win over
  `add_p`. *Rejected: any positive accuracy*: R's false labels. *Rejected: below 0.5 strictly*:
  0.5 is sound. *Rejected: `prefix:` winning, as R*: an option that does nothing, hidden.
  *Rejected: a keyword list*: what a partial one means is a question R never faces.

- **`ordinal/2` takes `prefix:`, `suffix:`, `big_mark:`, `rules:`, `trim:` and the styles; its
  rules see a negative's minus; a break none match raises (2026-10-31, Steve: "A" thrice; checked
  against scales 1.4.0).** R's rules read the break before `number()` scales it, so `scale = 10`
  writes `"10st"`; `decimal.mark` shows nothing at accuracy 1, and `accuracy` R refuses. The
  digits matched are the label's, unmarked, a `-` before a negative's, as R's text has it
  (`^1$` misses -1). R pastes suffixes in the rules' order of matching, so a break none match
  takes another's (`"1a" "2b" "3a" "4b"`); `rules: []` R fails on. *Rejected: `scale:` with the
  scaled number matched*: a second departure. *Rejected: the digits without the minus*: one on
  every negative. *Rejected: no suffix, or no label*: a gap in the rules hidden.

- **Plain bytes under binary units are `B`, where R writes `iB` (2026-10-31, Steve: "B"; checked
  against scales 1.4.0).** R's `cut_bytes()` puts its `iB` on the zero step too, so under
  `"auto_binary"` its own documented axis reads `"0 iB"`, and `1500` is `"1 500 iB"`; R's NEWS
  for `label_bytes()` says "it always uses 'B' as the symbol for bytes (#174)", and the
  development branch still has the slip. Every other label is R's; the tests pin R's rows with
  that suffix swapped. *Rejected: R's `iB`*: no unit, copied. *Rejected: refusing plain bytes
  under binary units*: an axis from 0 unusable.

- **`bytes/2`'s `units:` is `:auto_si`, `:auto_binary` or R's fixed-unit string, and it takes
  `number/2`'s options but `suffix:` and `scale_cut:`, `accuracy: nil` worked out (2026-10-31,
  Steve: "A" twice; checked against scales 1.4.0).** A fixed unit is the text written after the
  number, spelt as R spells it (`"kB"`, `"kiB"`, and `"KiB"` refused as R refuses it); the
  automatic ones are modes, atoms as the package's modes are. `accuracy:` defaults to 1, R's, and
  `nil` is R's `NULL`, an accuracy the data supplies; `suffix` and `scale_cut` R refuses.
  *Rejected: every unit an atom*: mixed-case atoms turned back into text. *Rejected: every unit
  a string*: a mode as a string. *Rejected: `:auto` for a worked-out accuracy*: a sentinel of its
  own.

- **A break `scale:` takes past the largest double is labelled `Inf`, as R labels it
  (2026-10-31, Steve: "Inf"; checked against scales 1.4.0).** Erlang raises where a double's
  arithmetic reaches an infinity, so every product, quotient and gap a break's label is worked
  from is taken to `:infinity` or `:neg_infinity` instead, and `Format` writes it. In
  `number/2`'s family, a break rounded past the largest double is `Inf` with its sign styled and
  no prefix or suffix, as R's `number()` overwrites it; one only scaled past it is `Inf` inside
  them; either takes no step, no cents and no part in the others' accuracy, and a gap past it
  leaves the accuracy 1, as R's `precision()` does. `scientific/2` writes `<Inf>`. All of 1,728
  random cases near the largest double matched R. *Rejected: raising*, as `number/2` did: an
  axis R draws, refused.

- **`scientific/2` takes `digits:`, `scale:`, `prefix:`, `suffix:` and `decimal_mark:`, and no
  `trim:` (2026-10-31, Steve: "A"; checked against scales 1.4.0).** `label_scientific()` takes
  `trim` but never hands it to `scientific()`, so its labels are always trimmed; `big.mark` and
  `nsmall`, which its `...` takes, change nothing in scientific notation. *Rejected: `trim:`
  honoured*: the superseded `scientific()`'s labels, which R's current labeller never gives.
  *Rejected: `trim:` taken and ignored*: R's exactly, an option that does nothing.

- **`digits:` is an integer from 1 to 22 under `scientific/2`, `log/2` and `format_log/2`
  (2026-10-31, Steve: "A"; checked against scales 1.4.0).** It is `format()`'s range, outside
  which `label_log()` already fails; `signif()` takes any number, a fraction rounded half up (2.5
  is 3) and 0 or below as 1, where `format()` truncates (2.9 is 2). No label shows more than 7
  significant digits, since `scientific` hands `format()` its default and `zapsmall()` rounds
  exponents to 7, and each function's documentation says so. *Rejected: any positive integer
  under `scientific/2`*: past 22, 22's labels. *Rejected: R's coercions*: two opposite roundings
  of a fraction, and a `digits: 0` that is surely a mistake.

- **A signed power is `{:signed, "-" | "+", {:power, base, exponent}}` (2026-10-31, Steve: "B";
  checked against scales 1.4.0 and svglite).** R's `label_log()` writes `-10^2` as a unary call
  around the power, −(10²), and plotmath draws the sign as an operator of its own, a symbol-font
  `−` or `+` and a gap before the base, as it draws an exponent's minus. So the sign wraps the
  power, the shape the entry beginning "`log/2` returns powers" agreed kept; a signed zero is
  `"0"`, and an exponent's minus stays in its text (`"-2"`). *Rejected: the sign in the base's
  text (`{:power, "-10", "2"}`)*: it reads as (−10)², and is split off again to draw.
  *Rejected: a sign on every power*: the agreed shape changed.

- **`log/2` refuses a base that is not a positive number other than 1, and an unsigned break at
  or below zero (2026-10-31, Steve: "A" twice; checked against scales 1.4.0).** R's text there is
  no power of anything: a base of 0 gives `0^0`, 1 `1^NaN`, a negative `-2^NaN`; under `signed =
  FALSE` a zero is `10^-Inf`, a negative `10^NaN`, and `zapsmall()`, beside an infinite exponent,
  rounds every other one whole, so 0.5 and 2 are both `10^0`. Both raise, the second an
  `ArgumentError` naming the break; `signed: :auto`, the default, signs such breaks. *Rejected:
  bases above 1 alone*: 0.5's powers are sound. *Rejected: R's text*: no infinity or NaN to
  write it from, and the sound breaks mislabelled. *Rejected: no label for such a break*: a
  mistake hidden.

- **`format_log/2` takes `base:`, `signed:` and `digits:` alone (2026-10-31, Steve: "A"; checked
  against scales 1.4.0).** They are `label_log()`'s arguments, `digits` the one `format()`
  argument a log label uses; `digits:` defaults to 7, `format()`'s own, under `format_log/2`, and
  to 3, `label_log()`'s, under `log/2`. R's `format_log()` hands its `...` to `format()`
  (`trim`, `nsmall`, `scientific`, `width`, marks), which can be added later without breaking
  anything. *Rejected: the `format()` arguments `Format` already writes*: rows to pin and a name
  for R's `scientific`, with no reader asking. *Rejected: `width` too*: `Format` has none.

- **R's `format()` for numbers is built rule for rule, `Labels.Format` grown from `Labels.Fixed`
  (2026-10-31, Steve: "A"; checked against R 4.6.1 and scales 1.4.0).** `scientific`,
  `number_auto` and `log` are thin wrappers over `format()`, whose labels depend on each other:
  the fewest significant digits up to `digits` that show every number, scientific notation for
  all where it is narrower, a shared mantissa, `e+05`, `nsmall`, padding. So `formatReal()` is
  ported whole, each number printed from its exact value half to even, as `Fixed` already printed
  plain decimals; all of 6,000 random vectors matched R, across digits 1 to 22, `nsmall`, both
  trims, marks and every notation. R's `scientific = FALSE` is plain unless more than 310
  characters wider, a margin measured by bisecting R, so `number()`'s labels are R's there too.
  *Rejected: Erlang's `~e` per labeller*: other digits and ties, labels no longer R's.

- **A missing break's label is `nil`, as R's labellers give `NA`, and Giggly draws it `NA`
  (2026-10-31, Steve: "A"; checked against scales 1.4.0 and ggplot2 4.0.3).** Each labeller gives
  `nil` for `nil` where R gives `NA`, and the text `"NA"` where R writes it (`wrap`;
  `number_auto` in its two `format()` ways, `nil` in the others, as R's `number()` gives and as
  both its ways give where R breaks on an `NA`, Steve: "A"; `dictionary`'s `nomatch:` for `nil` too); `comma`, `percent` and `currency` take `nil` as R's
  `number()` takes `NA`, which widens the others' untrimmed padding to its two characters. Giggly
  takes a `nil` label from a labels function, a list or a map's value and draws `NA`, as grid
  draws R's `NA` on axes and legends alike; the scale writes it, so a guide never sees `nil`
  (Steve: "A"), but among powers, where each guide writes it (Giggly's design log's entry beginning "A missing
  label among powers"). A discrete scale's labels function is handed `nil`, so the labellers must take
  it. *Rejected: refusing `nil`*: `wrap` and `dictionary` unusable on a missing level.
  *Rejected: the package writing `"NA"`*: not R's values, and a missing label then reads as text.

- **`log/2` returns powers as values, and Giggly draws them as plotmath draws `a^b` (2026-10-31,
  Steve: "A"; checked against scales 1.4.0 and svglite).** R's `label_log()` returns expressions
  (`10^3`), drawn as a base at the label's size and its exponent at 0.7 of it, raised, after the
  base, two texts in svglite's output. The package gives `{:power, base, exponent}`, each written
  as R deparses it (`10^0.301`, a base of e as `2.71828182845905`), or `"0"`; `format_log/2` is
  R's `format_log()`, text exactly. A label is then a string or a power. *Rejected: the text
  `10^3`*: not what R draws, and superscripts later would change the package's API. *Rejected:
  Unicode superscripts*: Liberation Sans lacks ⁰, ⁶, ⁹ and ⁻. *Rejected: leaving it out with
  plotmath*: the package touched again for it.

- **The date labellers take `Calendar.strftime/3` formats, as `date_labels:` does (2026-10-31,
  Steve: "A"; checked against scales 1.4.0).** `date/2`, `date_short/2` and `time/2` write R's
  defaults to the character, `%Y` unpadded as `DateBreaks.label/2` writes it; a format Calendar
  cannot write raises (`%e`, `%U`, `%W`, `%D`, `%F`, `%T`, `%R`, `%h`, `%k`, R's `%OSn`), and
  `%c`, `%x`, `%X` are Calendar's. `tz:` is R's, UTC unless given: a `DateTime` is shifted into it
  (`time_zone_database:`), a `Date`, `NaiveDateTime` or `Time` written as it is; `date_short/2`
  reads which parts change in each value's own zone and writes them in `tz`, as R does. `locale`
  is left out, since R needs stringi for it. *Rejected: R's conversions ported*: it reverses
  Giggly's design log's entry beginning "`date_breaks:` and `date_minor_breaks:`", and R's `%c`, `%x` and `%X` follow
  the machine's locale, so there is no one answer to match.

- **Labellers are composed with a pipe; `compose_label()` is left out (2026-10-31, Steve: "C").**
  R's `compose_label()` runs labellers in order, each handed the last one's output, and restores
  `NA`; in Elixir that is a pipe, which `Scales.Labels`' documentation shows under R's name, and
  `nil` is each labeller's to keep. *Rejected: `compose(breaks, labellers)`*: a function for what
  a pipe does. *Rejected: a function returning a labeller*: the package's functions take values
  (the entry beginning "The scales package's API").

- **`ordinal/2`'s rules are matched against the rounded number's whole digits (2026-10-31, Steve:
  "A"; checked against scales 1.4.0).** `rules:` is a list of `{suffix, regex}` pairs, Elixir's
  regular expressions taking Perl's syntax as R's `perl = TRUE` does, the first match winning, in
  order, repeats kept; `ordinal_english/0` gives R's. R matches its rules against
  `as.character()`, so a round number from 1e5 up is its scientific text there, and `ordinal(1e21)`
  is `...st`; here the digits are matched, documented as the one departure. *Rejected: R's
  `as.character()` exactly*: a second home for `Giggly.AsCharacter`'s rule, or moving that module
  into the package against Giggly's design log's entry beginning "`scales`, a package of R's
  scales half".

- **`n:` reaches every transformation's own breaks but time's, labels follow it, and numbers'
  `pretty()` rounds at R's measured switches (2026-10-29, Steve, increment 2's step 4: "A", "A",
  "A", "Agree", then "A"; checked against scales 1.4.0).** `Transform.breaks/3`'s `n:` reaches
  `Breaks.log/2` under log10 and R's date `pretty()` under dates and date-times, from 0 as R
  takes it, and `Transform.format/4` takes it too, as R's breaks carry their labels as names.
  The date steps gain R's trimming and added ticks, so `Breaks.pretty/2`, R's `breaks_pretty()`
  typed, is R's outside the extent too; times are numeric `pretty()` on seconds, as R breaks an
  `hms`, given back as `Time`s. R documents numbers' steps but the rounding to 1, 2, 5 or 10, so
  it rounds up from just above 1.4, 2.8 and 7, R's switches found by bisecting its output.
  *Rejected: time passing `n:` to `timespan`*: R's `transform_hms()` takes no number.
  *Rejected: Heckbert's 1.5, 3 and 7*: 91.4% of 7,191 ranges matched R, against 97.5%, twice
  R's breaks on the rest. *Rejected: R's tolerance at the ends*: only its C holds it, and its breaks there are
  not round. *Rejected: `pretty()`'s biases and shrinking*: they set the rule R leaves out.

- **Minor breaks a number or a width to each gap are R's `loop_breaks()`, the width's typed as
  `Breaks.width/3` is, the number's on numbers alone (2026-10-29, Steve: "A", increment 2's step
  3; checked against scales 1.4.0).** `MinorBreaks.n/3`, `width/4` and `log/2` are R's
  `minor_breaks_n()`, `minor_breaks_width()` and `minor_breaks_log()`, taking the limits and the
  breaks as ggplot2 hands a two-argument function, their values in R's order, a value laid twice
  kept once, 0 and -0 one value as R's `unique()` keeps them. R's `unlist()` drops a date's class,
  so on a date or date-time axis R gives bare days or seconds, which ggplot2 then refuses; here
  `width/4` gives what `Breaks.width/3` gives, `Date`s for dates, and `n/3` refuses dates, as a
  fraction of a day is no date. `width/4`'s `offset:` defaults to 0, where R has no default.
  *Rejected: both on numbers alone*: R's route works on no date axis, but a width's dates cost
  nothing and serve another tool.

- **Breaks for a log, exponential or timespan axis are R's, whole, and extended breaks take
  labeling's `only.loose` and `w` (2026-10-29, Steve, increment 2's step 2; checked against scales
  1.4.0).** `Breaks.log/2`, `exp/2` and `timespan/2` are R's `breaks_log()`, `breaks_exp()` and
  `breaks_timespan()`, R's breaks whole, the power or multiple either side of the limits
  included, as `extended/2` gives breaks outside them; log10's and the time scale's breaks call
  them. `exp/2` takes every option of `extended/2`, its fallback, as R passes `...`; `timespan/2`
  counts its limits in `:second` to `:week`, the package's step units, and gives seconds as
  numbers. A power is `:math.pow/2`'s, the double nearest it, where R's x86 long-double power is
  a bit off on 1.2 cubed and 1.1 to the fourth. Refused where R fails or never ends: limits of 0
  or below, a base of 1 or below, weights not positive for simplicity, coverage or density, one
  nice number. *Rejected: R's power*: only a port of glibc's `powl` reproduces its last bit.
  *Rejected: Giggly's own unit names (`:secs`)*: the package names a step's units once.

- **Breaks a width apart take numbers, dates, date-times and times, a step as `Date.shift/2`
  writes one (2026-10-29, Steve, increment 2's step 1; checked against scales 1.4.0).**
  `Breaks.fullseq/3` and `Breaks.width/3` are R's `fullseq()` and `breaks_width()`, chosen by the
  limits' type as R's generics are by class (Steve: "A"), so a breaks function on a date scale,
  handed `Date`s as R hands them, can call them, and another charting tool has date breaks too. A
  step is `[month: 1]` where R takes `"1 month"`, one unit for a width; an offset is a number, or
  a list of steps moving each break in turn, as R moves it by each of a vector; a month past its
  end is carried into the next, as R normalises one, so the breaks keep R's order, unsorted.
  `pad:` beside dates is refused, where R ignores it; a time of day wraps past midnight, where
  R's `hms` runs on. *Rejected: numbers alone*: dates' breaks stay behind `date_breaks:`, out of
  reach of a breaks function and of other tools. *Rejected: R's `"1 month"`*: Giggly's
  design log's entry beginning "`date_breaks:` and `date_minor_breaks:` are a step".

- **A squished value is R's `oob_squish()`, finite numbers only, and an end of `nil` squishes
  nothing (2026-10-29, Steve, increment 1's step 6; checked against scales 1.4.0).** `squish/2`
  takes a list and a range as `censor/2` does: a finite number below the low end is moved up to
  it, then one above the high end down to it, in R's order, so a range given high to low puts
  every number at its high end and a zero-wide one every number at it; a moved value takes the
  end as given, a negative zero's sign included. `nil`, the infinities, values that are not
  numbers and `:nan` are kept, NaN as R keeps it (Steve: "A"), and a `nil` end squishes nothing
  on its side, as R's `NA` end does. *Rejected: NaN made `nil`*: not R's answer, and a plot draws
  both as missing.

- **A colour helper takes one colour and gives R's answer, out-of-range arguments capped as
  farver caps them (2026-10-28, Steve, increment 1's step 4; checked against scales 1.4.0 and
  farver 2.1.2).** `alpha/2`, `muted/2`, `with_hcl/2`, `lighter/2`, `darker/2`, `saturate/2` and
  `shift/2`, one colour a call as `mix/3` takes it (Steve: "A"). Each is R's, Steve "A" to each:
  `:none` gives `:none`; an alpha of `nil` keeps the colour's own, one outside 0 to 1 is clamped;
  `muted` and `with_hcl` drop the colour's alpha unless given one; a hue, chroma or luminance is
  capped, the hue too, where `shift` wraps it. `from_hcl/3` caps, so the hue palette, which
  departed beyond R's bounds, now takes each hue modulo 360 first as R does. An alpha byte of 1 is
  `01` (Steve: "B"), R's answer for several colours; R writes one alone opaque. *Rejected: lists
  as R's vectors*: `mix/3` and its geom callers would change to match. *Rejected: refusing what R
  caps*: refusing is Giggly's. *Rejected: the textbook HSL formula written out* (Steve: "B"): the
  library's `Color.HSL` is a byte off R at exact ties, about 1% of colours at the default amount.

- **A gradient's values move a place as R's `approxfun()` does, its alpha blends, and
  `"transparent"` is R's white (2026-10-28, Steve, increment 1's step 3; checked against scales
  1.4.0 and farver 2.1.2).** `{:gradient, colors, values}`, R's `pal_gradient_n(colours, values)`:
  a place moved along straight lines through the values, each at its `seq()` place, then blended;
  outside them, or outside 0 to 1, `nil`. The values are R's exactly (Steve: "A"): sorted, so
  unsorted ones reverse the gradient, a `nil` dropped, equal ones at their places' mean, any
  count, fewer than two raising. *Rejected: the package refusing all but increasing values*: it
  refuses answers R gives, and refusing is Giggly's (`values:`, step 5). The alpha is a fourth
  channel, its byte rounded half to even. `"transparent"`, and `:none` in a gradient, are R's
  `#FFFFFF00` (Steve: "B"). *Rejected: CSS's black*: through a partial alpha it shows, a muddy
  grey mid-gradient, a look neither R nor CSS gives, since CSS blends gradients premultiplied.

- **A palette of one kind is converted inside the other kind's function (2026-10-28, Steve,
  increment 1's scope and step 2; checked against scales 1.4.0).** `continuous/2` takes a discrete
  palette as R's `as_continuous_pal()` does, colours as a gradient through its `nlevels/1`, numbers
  joined by straight lines; `discrete/2` samples a continuous one at R's `seq(0, 1, length.out =
  n)`. A scale holds the palette as given. *Rejected: separate conversion functions*: a hue scale
  would hold 255 colours, or a new `{:sampled, ...}` value would join the palettes. A manual
  palette's type is R's guess, `nil` where R names a storage type (`"character"`). *Rejected:
  guessing Giggly's own forms* (shape atoms `:shape`, tuples `:linetype`): beyond R, and no reader
  of the type tells them apart. `:identity` and `{:abs_area, max}`, untyped in R, which hands them
  back unchanged (3 levels give the one number 3), are refused by `discrete/2`. *Rejected:
  sampling them as the others*: an answer R never gives.

- **A palette's name is one of scales' own 45, in any case (2026-10-28, Steve, increment 1's
  scope; checked against scales 1.4.0).** `named/1` is R's `get_palette()` for the names scales
  registers itself, lowercased as R lowercases: the 35 brewer palettes, the 8 viridis options,
  `"grey"` and `"hue"`, each with R's defaults; any other raises listing them, a documented
  departure, since R's registry also holds grDevices' (138 names in all, `"Okabe-Ito"` among
  them). *Rejected: `palette.colors()`'s 14 and `hcl.colors()`'s 79*: R's own GPL tables, used by
  nothing in the books or notebooks. A colour, for a manual palette's guessed type, is a string
  `ColorOperations.parse/1` reads, so `"transparent"` is one and `"grey50"` is not, the reverse of
  R's test, which reads R's own colour names.

- **The standalone colour mappers are left out (2026-10-28, Steve: "D", increment 1's scope).**
  R's `col_numeric()`, `col_bin()`, `col_factor()` and `col_quantile()` map values straight to
  colours, outside any scale. The first two are a trained range, a rescaling and a palette, three
  calls the package has; the others need breaks and quantiles of their own; nothing in the books
  or the notebooks calls one. Steve: "Why do this if giggly isn't going to use it". *Rejected: the
  four in `Scales.ColorOperations`*: a second road to what a scale does, with no user in the
  evidence.

- **A brewer palette is RColorBrewer's sets, named as R spells them; dichromat is left out
  (2026-10-28, Steve, increment 1's scope; checked against scales 1.4.0, RColorBrewer 1.1-3 and
  dichromat 2.0-1).** `{:brewer, %{palette: "Set1", direction: 1}}` gives R's `pal_brewer()`:
  each palette has a hand-picked set per count, so the 265 sets are copied by R's own script into
  `priv/palettes/brewer.csv` with ColorBrewer's Apache 2.0 notice (no Hex package has them). Names
  are strings as ColorBrewer coined them and every library spells them (`"BrBG"`), matched
  exactly as R matches, `brewer_palettes/1` listing each type's in R's order for a number.
  *Rejected: snake-case atoms (`:br_bg`)*, viridis's form, since they invent spellings a user
  translates from every reference. *Rejected: R-case atoms (`:BrBG`)*: unidiomatic. *Rejected:
  `pal_dichromat()`*: its 17 schemes are the GPL-2 dichromat package's, which scales only
  suggests; nothing in the books or notebooks uses it, and its maintainer points users elsewhere.

- **The scales package's API is what a user holds the inputs to or Giggly calls, named for R's
  families (2026-10-27, Steve, the split's step 2; checked against scales 1.4.0).** API: the root,
  `Breaks`, `MinorBreaks`, `Labels` (`Format` merged in, since scales 1.1.0 renamed `*_format`
  to `label_*`), `Transform`, `Palette`, `Bounds`, `DataRange`, `ColorOperations`, Giggly's
  helpers among them. Internal: `Labels.Format`, the `Transform.*` modules behind a name, and
  `DateBreaks`, which takes days or seconds and a clock, R's representation, through `Transform`.
  A function is R's name less its family's prefix (`Breaks.extended`), its doc naming R's, but
  Elixir's words where R's differ (`:time` a time of day); options are R's arguments spelled out;
  a range is `{low, high}`; a function takes a list where R takes a vector, `nil` as `NA`.
  `DataRange` stays, for R's `Range` classes. The root holds the shared conventions once and a
  worked example. *Rejected: `DateBreaks` as API now*: a signature the breaks increment may break.
  *Rejected: `Format` beside `Labels`*: R's dropped word, two places to look. *Rejected: R's whole
  names*: `Breaks.breaks_extended` stutters. *Rejected: one value for `rescale` and continuous
  palettes*: no room for R's `from` default. *Rejected: `Scales.Training`*: it names the activity.

- **The package gives R's values and Giggly refuses; each test figure has one home (2026-10-27,
  Steve, the split's step 2).** The package's manual (list), shape and line-type palettes give
  R's values, `nil` past their end, as R gives `NA` and warns; ggplot2's matching by name and by
  breaks, every refusal of too few values, and the ordinal palettes (`scale_alpha_ordinal()`'s
  and `scale_size_ordinal()`'s, no `pal_*`) move to `Giggly.Scale.Discrete`. R's `rescale_mid()`
  and `rescale_max()` move from `Giggly.Scale` to `Scales.Bounds`, which gives R's infinities and
  NaN; Giggly raises at an infinity. The package's figures are pinned in `test/scales` alone,
  which calls nothing in Giggly, Giggly's tests keeping Giggly's decisions, and the package's
  tests alone run all of `lib/scales`. *Rejected: the
  package raising past its end*: the check run twice, and not R's answer. *Rejected: the ordinal
  palettes kept in the package*: not scales'. *Rejected: package tests beside Giggly's copies*
  (Steve: "So you want to test the scales package in two places one of which is not the
  package").

- **A date-time's breaks under a day are `prettyDate()`'s steps, the table `Scales.DateBreaks`
  holds for dates extended (2026-10-26, Steve).** Seconds (1, 2, 5, 10, 15, 30), minutes (the
  same) and hours (1, 3, 6, 12), each with R's label format and unit to truncate to, chosen by
  the rule the table already has, with R's widening of an extent under a second, its added ticks
  and its trimming. R's searches for a finer step, which the mutation pass found never decide,
  are left out, dates' included: on 16,400 of R's extents, 6,300 round the spans where two steps
  are equally close to five, and 20,000 with `n` from 2 to 20, they never came closer.
  *Rejected: extended breaks on the range in seconds, minutes or hours*, R's time scale's: it
  matched R's date-time breaks on 29% to 56% of random extents, counting six hours from 1970, not
  local midnight.

- **A local time a change of offset skips or repeats is read as R reads it where R has a rule,
  and as the earlier where it has none (2026-10-27, Steve: "A").** Truncated to a minute or an
  hour, a time keeps its own offset, as R keeps its daylight-saving flag; truncated to a day or
  longer, or stepped by days, months or years, its wall-clock time is read again: one a change
  skips at the offset before it, as glibc's `mktime()` reads every daylight-saving start (1,511 of
  1,511 skipped midnights since 1970), and one a change repeats as the earlier of its instants.
  R's pick there is the offset glibc last used, so one plot breaks two ways by what R converted
  before (Havana's 6-hour breaks on 3 November 2024 at 05:00 or 06:00). *Rejected: the later
  midnight*: two rules, and R's only after a winter time. *Rejected: `DateTime.from_naive/3`'s
  `after` for a skipped time*: not R's inside a gap (New York's 02:30). *Left:* glibc's reading
  of a skipped midnight of a change of standard offset (17 of 52 after it) and of a double summer
  time (1 of 2); its search is undocumented, and porting it is out.

- **A time of day's labels are hms's, less two of its marks, and a labels function is handed
  `Time`s wrapped past midnight (2026-10-27, Steve: "Agree with your recommendations").** A break
  is rounded to the microsecond and written as hms writes it, `24:00:00` and `-00:00:30`
  included. *Rejected: hms's six zero decimals* where labeling's arithmetic leaves a break a
  rounding error off a whole second (`10:24:00.000000`, on about 1 in 15 random hour-scale
  axes): noise, not a time. *Rejected: hms's padding* to the widest label (`" 00:00:00"` beside
  `-00:00:30`), console alignment, reached only through a fine width at midnight or a wide
  expand. *Rejected: `Duration`s or seconds for a labels function*: `Calendar.strftime/3` writes
  neither, and a `Time` is what `breaks:` and `limits:` take; `24:00:00` arrives as
  `~T[00:00:00]`, as `date_labels:` and R's `format()` write it. Departures from R: `date_breaks:`
  takes seconds, minutes and hours, where R's days and longer mark only midnights; a format
  writing a date (`"%Y"`) is refused at the call, where R writes 1970-01-01; numbers on a time
  axis are refused, where R places them as seconds.

- **Extended breaks keep their remainder in doubles where R's is long double (2026-10-27, Steve:
  "Leave it").** Past 10^22 a step and its breaks are rounded, and R's long-double `%%` keeps that
  rounding as a break's remainder, denying a sequence through zero its bonus where the remainder
  in doubles, exactly 0, grants it: on ranges over about 3e23 wide reaching zero, 95 of 1,500
  depart, none narrower (`Scales.Breaks`' opening comment). *Rejected: the remainder computed
  exactly in integers*, which matches R there but costs every candidate scored, for ranges no
  plot of ordinary data reaches.

- **A discrete scale fed levelled and plain values trains as R's `discrete_range()`, remembering
  whether its first values had levels (2026-10-22, Steve, scoping Phase 3's tenth increment;
  checked in R).** Each training (one layer's column, on the panels the scale serves) brings the
  levels its rows hold, as R's `drop = TRUE`, or its plain values sorted, and adds those the scale
  lacks, matched by `Scales.DataRange.key/1`: a factor's levels lead whichever layer brings them, so
  factor (b, a) and text (c, a) train to b, a, c in either order. A scale whose first values had
  levels then adds each new value after the rest; one whose first were plain sorts everything at
  each plain training, so text, factor, text (d, 0) gives 0, a, b, c, d where factor first gives
  b, a, c, 0, d. `Scale.Discrete` gains a documented field saying which, `factor`, R's name for
  it; Giggly already trains in ggplot2's order, a layer and a column at a time. *Rejected: levels
  first, plain values sorted after, whatever the order* — no field, but a departure from R from
  the third training on.

- **A gradient is one palette of any number of colours, and gradient2's midpoint is the scale's
  (2026-10-19, part of the agreed step 5).** R's three gradients are one palette,
  `pal_gradient_n()`: each colour in L*a*b*, a straight line between neighbours as `approxfun()`
  draws it, exact at each colour. So `{:gradient, colors}` replaces `{:gradient, {low, high}}`;
  generalised from two colours, Giggly's blend matches R on all 30,054 colours sampled from six
  colour sets, through the `color` library with farver's constants, no new library. gradient2
  centres its colours on the midpoint by R's `rescale_mid()`, which R keeps on the scale as its
  rescaler, so `Scale.Continuous` holds it as its `rescaler`, `{:mid, midpoint}`; its colour bar's
  ticks are placed over the limits, as R places them, ignoring it. *Rejected: a palette per
  function*, three copies of one blend. *Rejected: the midpoint in the palette*: a palette takes a
  place from 0 to 1, and the ticks never go through the midpoint.

- **`Scales.Labels`'s `comma/2`, `percent/2` and `currency/2` take every option of scales
  1.4.0's `label_comma()`, `label_percent()` and `label_currency()` (2026-10-18, Steve).**
  `currency`, since scales 1.4.0 supersedes `label_dollar()` with it, the output the same (Giggly's
  design log's entry beginning "Giggly exposes no function" holds for scales too); the notebook draws
  `label_dollar()` with it. Each takes `accuracy:`, `scale:`, `prefix:`, `suffix:`, `big_mark:`,
  `decimal_mark:`, `trim:`, `style_negative:`, `style_positive:` and `scale_cut:`, and currency
  `largest_with_fractional:` (Steve: "do the options you were going to defer"). `scale_cut:` is a
  list of `{suffix, threshold}` pairs, which R's `cut_short_scale/1`, `cut_long_scale/1`,
  `cut_si/1` and `cut_time_scale/1` return; it must hold a threshold of 0, since without one R
  misaligns the step below (`c(m = 60, h = 3600)` writes 5400 as `5 400NA`). Its options are
  NimbleOptions schemas, as every public option in Giggly is, so its boundary lists NimbleOptions
  (Steve). *Rejected: `dollar/2`*, the name ggplot2's example calls: superseded. *Rejected: the
  first four options alone*: separators, padding, sign styles and cuts are R's too. *Rejected:
  `scale_cut: :short_scale`*: two shapes in one option. *Rejected: any list, each value taking
  its own lower step*: a label R never writes. *Rejected: options checked by hand, so the
  boundary lists nothing*: a second error for a bad option, and docs kept beside the checks.

- **Colours are CSS's names and hex forms, carried as uppercase hex strings (2026-10-16, Steve).**
  A colour is `#RRGGBB`, or `#RRGGBBAA` when it carries its own alpha, and `:none` is R's `NA`:
  the form R, CSS and the scene already use, so it sits in a frame column, a scale's `na_value`
  and a legend key as any string does. A name CSS lacks (`grey50`) raises at the call. A notebook
  keeps ggplot2's name with CSS's meaning and notes where the drawing differs (CSS's `green` is
  `#008000`, R's `#00FF00`), and writes a name CSS lacks as its hex, naming the R colour. A row's
  `alpha` replaces a colour's own alpha, as `scales::alpha()` does, and a missing one keeps it; a
  bar's border is never given the row's, as `GeomRect` draws it. *Rejected: R's 657 names*
  (recommended), whose `gray`, `green`, `maroon` and `purple` are not CSS's; *CSS's plus R's
  extras*, a vocabulary of neither; *a struct*, a public type in every column and scale for what a
  string carries. `transparent` is R's white, not CSS's black (the entry beginning "A gradient's
  values move a place").

- **R's exact colours come from the `color` package's conversions, handed farver's constants
  (2026-10-16, Steve: no hand-rolled colour maths).** Both of ggplot2's default palettes go
  through farver (`pal_hue()` too, not `hcl()`). `Color.Conversion.Lindbloom` takes the matrix and
  the white point as arguments: given farver's sRGB matrices, the white point farver's R code
  makes from D65's chromaticity (0.31271, 0.32902) rather than the textbook 95.047 and 108.883, and
  each channel rounded half to even, it matches R on 50,400 HCL values, `pal_hue()` for 1 to 40
  levels, and all but one of 35,007 gradient samples, a colour below L* 8 where farver keeps
  0.008856 and 7.787. `Scales.ColorOperations` is its only caller; a gradient's interpolation in
  Lab is the scale's, as in R's scales. *Rejected: `color`'s own conversions*, 12 of 820 hue
  colours a byte out; *porting farver*; *`Giggly.Color`* (Steve: `Color.` could not be grepped
  apart from the library's) and *`Giggly.Colors`* (Steve).
- **A spread past the largest double halves its ends (2026-11-19, Steve: "1", fix the chain so
  plots that wide draw as R draws them).** R's `seq(low, high, length.out = n)` gives numbers
  where `high - low` passes the largest double, as `labeling::extended()` spreads such a range;
  `?seq` says nothing of how. Measured on nine ranges, from both ends at the largest double to
  ranges just past it, of 2 to 11 values, its numbers are those between `low / 2` and `high / 2`
  by the usual steps, doubled, to the last digit, so `Palette.spread/2` does that where the
  subtraction overflows, and `Breaks.extended/2` spreads its widest ranges through it rather than
  a copy. `Bounds.zero_range?/1` subtracts through `Scales.Double` beside it, giving R's FALSE.
  *Rejected: translating `seq.default()`*, R's source; *refusing such ranges*, where R draws.

## 5. Testing approach

Expected values are R's own output, never the package's and never worked out by hand: R 4.6.1 with
scales 1.4.0 in the local Docker image `giggly-r:ggplot2-4.0.3` (r-base with r-cran-ggplot2; its
`-hms` variant adds hms 1.1.4), each golden labelled with the image and the call, and the larger
tables under `test/scales/fixtures/` named for R's version. A figure resting on the platform's
maths is R's within the rules' bounds, never one C library's double (§4, the entry beginning "The
platform's"). Each test figure has one home: a decision about how Giggly uses the package is
tested in Giggly.

## 6. Milestone log

One line per milestone, newest first: the date, the commit's subject as its title (so
`git log --grep` finds it), and the §4 entries it settled. The commit message tells the story.
Milestones before the import are Giggly's, in its design log.

- 2026-11-02 — Import the scales package from giggleton/giggly@cd7f8da (`8a84d4c`), and make it a
  project of its own; §4: the eight entries from "The package was complete when it was carved out
  of Giggly" to "The carve-out goes in one order".

## 7. Deferred / open questions

Open: whether the package's tests alone kill its mutants, which every pass before the carve-out
ran beside Giggly's tests; each commit's pass covers its own lines (§4, the entry beginning
"Mutation testing came with the package").
