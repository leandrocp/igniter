defmodule Mix.Tasks.Igniter.InstallPhoenix do
  use Igniter.Mix.Task

  @example "mix igniter.install_phoenix . --module MyApp --app my_app"
  @shortdoc "Creates a new Phoenix project in the current application."

  @moduledoc """
  #{@shortdoc}

  ## Example

  ```bash
  #{@example}
  ```

  ## Options

    * `--app` - the name of the OTP application

    * `--module` - the name of the base module in
      the generated skeleton

    * `--database` - specify the database adapter for Ecto. One of:

        * `postgres` - via https://github.com/elixir-ecto/postgrex
        * `mysql` - via https://github.com/elixir-ecto/myxql
        * `mssql` - via https://github.com/livehelpnow/tds
        * `sqlite3` - via https://github.com/elixir-sqlite/ecto_sqlite3

      Please check the driver docs for more information
      and requirements. Defaults to "postgres".

    * `--adapter` - specify the http adapter. One of:
        * `cowboy` - via https://github.com/elixir-plug/plug_cowboy
        * `bandit` - via https://github.com/mtrudel/bandit

      Please check the adapter docs for more information
      and requirements. Defaults to "bandit".

    * `--no-assets` - equivalent to `--no-esbuild` and `--no-tailwind`

    * `--no-dashboard` - do not include Phoenix.LiveDashboard

    * `--no-ecto` - do not generate Ecto files

    * `--no-esbuild` - do not include esbuild dependencies and assets.
      We do not recommend setting this option, unless for API only
      applications, as doing so requires you to manually add and
      track JavaScript dependencies

    * `--no-gettext` - do not generate gettext files

    * `--no-html` - do not generate HTML views

    * `--no-live` - comment out LiveView socket setup in your Endpoint
      and assets/js/app.js. Automatically disabled if --no-html is given

    * `--no-mailer` - do not generate Swoosh mailer files

    * `--no-tailwind` - do not include tailwind dependencies and assets.
      The generated markup will still include Tailwind CSS classes, those
      are left-in as reference for the subsequent styling of your layout
      and components

    * `--binary-id` - use `binary_id` as primary key type in Ecto schemas

    * `--verbose` - use verbose output

  When passing the `--no-ecto` flag, Phoenix generators such as
  `phx.gen.html`, `phx.gen.json`, `phx.gen.live`, and `phx.gen.context`
  may no longer work as expected as they generate context files that rely
  on Ecto for the database access. In those cases, you can pass the
  `--no-context` flag to generate most of the HTML and JSON files
  but skip the context, allowing you to fill in the blanks as desired.

  Similarly, if `--no-html` is given, the files generated by
  `phx.gen.html` will no longer work, as important HTML components
  will be missing.

  """

  def info(_argv, _source) do
    %Igniter.Mix.Task.Info{
      group: :igniter,
      example: @example,
      positional: [:base_path],
      schema: [
        app: :string,
        module: :string,
        database: :string,
        adapter: :string,
        assets: :boolean,
        dashboard: :boolean,
        ecto: :boolean,
        esbuild: :boolean,
        gettext: :boolean,
        html: :boolean,
        live: :boolean,
        mailer: :boolean,
        tailwind: :boolean,
        binary_id: :boolean,
        verbose: :boolean
      ]
    }
  end

  def igniter(igniter) do
    elixir_version_check!()

    if !Code.ensure_loaded?(Phx.New.Generator) do
      Mix.raise("""
      Phoenix installer is not available. Please install it before proceding:

        mix archive.install hex phx_new

      """)
    end

    if igniter.args.options[:umbrella] do
      Mix.raise("Umbrella projects are not supported yet.")
    end

    %{base_path: base_path} = igniter.args.positional

    generate(igniter, base_path, {Phx.New.Single, Igniter.Phoenix.Single}, igniter.args.options)
  end

  defp generate(igniter, base_path, {phx_generator, igniter_generator}, opts) do
    project =
      base_path
      |> Phx.New.Project.new(opts)
      |> phx_generator.prepare_project()
      |> Phx.New.Generator.put_binding()
      |> validate_project()

    igniter
    |> Igniter.compose_task("igniter.add_extension", ["phoenix"])
    |> igniter_generator.generate(project)
  end

  defp validate_project(%Phx.New.Project{opts: opts} = project) do
    check_app_name!(project.app, !!opts[:app])
    check_module_name_validity!(project.root_mod)

    project
  end

  defp check_app_name!(name, from_app_flag) do
    unless name =~ Regex.recompile!(~r/^[a-z][a-z0-9_]*$/) do
      extra =
        if !from_app_flag do
          ". The application name is inferred from the path, if you'd like to " <>
            "explicitly name the application then use the `--app APP` option."
        else
          ""
        end

      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}" <> extra
      )
    end
  end

  defp check_module_name_validity!(name) do
    unless inspect(name) =~ Regex.recompile!(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp elixir_version_check! do
    unless Version.match?(System.version(), "~> 1.15") do
      Mix.raise(
        "mix igniter.install_phoenix requires at least Elixir v1.15\n " <>
          "You have #{System.version()}. Please update accordingly."
      )
    end
  end
end
