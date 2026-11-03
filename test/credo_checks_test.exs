defmodule ScalesCredo.ChecksTest do
  # The one file that loads the repo-local credo checks: requiring a source twice in one VM
  # redefines its module, and the warning fails the gate (`.credo/checks/README.md`).
  use Credo.Test.Case, async: true

  checks = Path.expand("../.credo/checks/*.ex", __DIR__)

  for path <- Path.wildcard(checks) do
    Code.require_file(path)
  end

  alias ScalesCredo.Check.{PassTimeZoneDatabase, ZipMap}

  # Credo is a `runtime: false` dependency, so its services, which parse a source, start here.
  setup_all do
    {:ok, _applications} = Application.ensure_all_started(:credo)
    :ok
  end

  # A module whose one function's body is `body`, as a source file credo can read.
  defp source(body) do
    to_source_file("""
    defmodule Sample do
      def run(positions, labels) do
        #{body}
      end
    end
    """)
  end

  describe "ZipMap" do
    test "a zip piped into a map is reported at the map, naming the one-pass function" do
      """
      positions
        |> Enum.zip(labels)
        |> Enum.map(fn {position, label} -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue(fn issue ->
        assert {issue.line_no, issue.column, issue.trigger} == {5, 6, "Enum.map"}
        assert issue.message =~ "Enum.zip_with"
      end)
    end

    test "a zip of a list of enumerables piped into a map is reported" do
      """
      [positions, labels]
        |> Enum.zip()
        |> Enum.map(fn {position, label} -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue()
    end

    test "a zip call piped into a map is reported" do
      """
      Enum.zip(positions, labels) |> Enum.map(fn {position, label} -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue()
    end

    test "a zip and map in the middle of a longer pipe are reported" do
      """
      positions
        |> Enum.sort()
        |> Enum.zip(labels)
        |> Enum.map(fn {position, label} -> {position, label} end)
        |> Enum.reverse()
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue()
    end

    test "a zip passed to a map is reported" do
      """
      Enum.map(Enum.zip(positions, labels), fn {position, label} -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue()
    end

    test "a piped zip passed to a map is reported" do
      """
      Enum.map(positions |> Enum.zip(labels), fn {position, label} -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> assert_issue()
    end

    test "a zip with in one pass is not reported" do
      """
      Enum.zip_with(positions, labels, fn position, label -> {position, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> refute_issues()
    end

    test "a zip piped into something other than a map is not reported" do
      """
      positions
        |> Enum.zip(labels)
        |> Map.new()
      """
      |> source()
      |> run_check(ZipMap)
      |> refute_issues()
    end

    test "a map of something other than a zip is not reported, piped or passed" do
      """
      sorted = positions |> Enum.sort() |> Enum.map(fn position -> position end)
      Enum.map(Enum.sort(labels), fn label -> label end)
      Enum.map(labels |> Enum.sort(), fn label -> {sorted, label} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> refute_issues()
    end

    test "a zip or a map from another module than Enum is not reported" do
      """
      lazy = positions |> Stream.zip(labels) |> Enum.map(fn pair -> pair end)
      positions |> Enum.zip(labels) |> Stream.map(fn pair -> {lazy, pair} end)
      """
      |> source()
      |> run_check(ZipMap)
      |> refute_issues()
    end
  end

  describe "PassTimeZoneDatabase" do
    test "a DateTime call leaving out its database is reported at the call, naming its arity" do
      """
      instant = DateTime.from_unix!(0)
      DateTime.shift_zone(instant, "Etc/UTC")
      """
      |> source()
      |> run_check(PassTimeZoneDatabase)
      |> assert_issue(fn issue ->
        assert {issue.line_no, issue.column, issue.trigger} == {4, 1, "DateTime.shift_zone"}
        assert issue.message =~ "`DateTime.shift_zone/2` takes its time zone database from config"
      end)
    end

    test "each function and arity that defaults the database is reported" do
      for call <- [
            ~s{DateTime.new(date, time)},
            ~s{DateTime.new(date, time, "Etc/UTC")},
            ~s{DateTime.new!(date, time)},
            ~s{DateTime.new!(date, time, "Etc/UTC")},
            ~s{DateTime.from_naive(naive, "Etc/UTC")},
            ~s{DateTime.from_naive!(naive, "Etc/UTC")},
            ~s{DateTime.shift_zone!(instant, "Etc/UTC")},
            ~s{DateTime.now("Etc/UTC")},
            ~s{DateTime.now!("Etc/UTC")},
            ~s{DateTime.add(instant, 1)},
            ~s{DateTime.add(instant, 1, :hour)},
            ~s{DateTime.shift(instant, hour: 1)},
            ~s{Calendar.get_time_zone_database()}
          ] do
        issues =
          call
          |> source()
          |> run_check(PassTimeZoneDatabase)

        assert [_issue] = issues, call
      end
    end

    test "a piped call is counted at the arity the pipe gives it, and a capture at its own" do
      """
      instant |> DateTime.add(1, :hour)
      Enum.map(instants, &DateTime.shift_zone!(&1, "Etc/UTC"))
      Enum.map(instants, &DateTime.shift(&1, [hour: 1], database))
      zone |> DateTime.now!(database) |> DateTime.add(1, :hour, database)
      fun = &DateTime.now/1
      """
      |> source()
      |> run_check(PassTimeZoneDatabase)
      |> assert_issues(fn issues ->
        found = Enum.map(issues, fn issue -> {issue.line_no, issue.trigger} end)

        assert Enum.sort(found) ==
                 [{3, "DateTime.add"}, {4, "DateTime.shift_zone!"}, {7, "DateTime.now"}]
      end)
    end

    # The piped call is replaced by its arguments for the walk to read on: what is piped into it,
    # and each argument, are read as any other code is.
    test "a call piped into a DateTime call, or one of its arguments, is still read" do
      """
      DateTime.shift_zone!(instant, "Etc/UTC") |> DateTime.to_unix()
      later |> DateTime.diff(DateTime.now!("Etc/UTC"))
      """
      |> source()
      |> run_check(PassTimeZoneDatabase)
      |> assert_issues(fn issues ->
        found = Enum.map(issues, fn issue -> {issue.line_no, issue.trigger} end)
        assert Enum.sort(found) == [{3, "DateTime.shift_zone!"}, {4, "DateTime.now!"}]
      end)
    end

    test "a call passing the database, or a function that takes none, is not reported" do
      """
      DateTime.new(date, time, "Etc/UTC", database)
      DateTime.from_naive(naive, zone, Calendar.UTCOnlyTimeZoneDatabase)
      instant |> DateTime.shift_zone(zone, database)
      DateTime.add(instant, 1, :hour, database)
      DateTime.from_unix!(0)
      DateTime.to_unix(instant, :microsecond)
      NaiveDateTime.add(naive, 1, :second)
      Calendar.strftime(instant, "%H")
      """
      |> source()
      |> run_check(PassTimeZoneDatabase)
      |> refute_issues()
    end
  end
end
