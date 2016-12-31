defmodule Mix.Tasks.Openmaize.Gen.Phoenixauth do
  use Mix.Task

  import Openmaize.Utils

  @moduledoc """
  Create modules for authorization and, optionally, email confirmation.

  ## Options

  There are two options:

    * confirm - add functions for email confirmation and password resets
      * the default is false
    * api - create files to authenticate an api instead of a html application
      * the default is false

  ## Examples

  In the root directory of your project, run the following command (add `--confirm`
  if you want to create functions for email confirmation):

      mix openmaize.gen.phoenixauth

  If you want to create files for an api, run the following command:

      mix openmaize.gen.phoenixauth --api

  """

  @phx [
    {:eex, "session_controller.ex", "web/controllers/session_controller.ex"},
    {:eex, "session_controller_test.exs", "test/controllers/session_controller_test.exs"},
    {:eex, "session_view.ex", "web/views/session_view.ex"},
    {:eex, "user_controller.ex", "web/controllers/user_controller.ex"},
    {:eex, "user_controller_test.exs", "test/controllers/user_controller_test.exs"},
    {:eex, "user_view.ex", "web/views/user_view.ex"},
    {:eex, "test_helpers.ex", "test/support/test_helpers.ex"},
    #{:eex, "user_migration.exs", "priv/repo/migrations/#{timestamp()}_create_user.exs"},
    {:eex, "user_model.ex", "web/models/user.ex"},
    {:eex, "user_model_test.exs", "test/models/user.exs"},
    {:eex, "router.ex", "web/router.ex"}
  ]

  @phx_api [
    {:eex, "phx_api/auth_view.ex", "web/views/auth_view.ex"},
    {:eex, "phx_api/auth.ex", "web/controllers/auth.ex"},
    {:eex, "phx_api/changeset_view.ex", "web/views/changeset_view.ex"}
  ]

  @phx_api_confirm [
  #{:eex, "mailer.ex", "lib/#{base_name()}/mailer.ex"},
    {:eex, "password_reset_controller.ex", "web/controllers/password_reset_controller.ex"},
    {:eex, "password_reset_controller_test.exs", "test/controllers/password_reset_controller_test.exs"},
    {:eex, "password_reset_view.ex", "web/views/password_reset_view.ex"}
  ]

  @phx_html [
    {:eex, "phx_html/authorize.ex", "web/controllers/authorize.ex"},
    {:text, "phx_html/app.html.eex", "web/templates/layout/app.html.eex"},
    {:text, "phx_html/index.html.eex", "web/templates/page/index.html.eex"},
    {:text, "phx_html/session_new.html.eex", "web/templates/session/new.html.eex"},
    {:text, "phx_html/user_edit.html.eex", "web/templates/user/edit.html.eex"},
    {:text, "phx_html/user_form.html.eex", "web/templates/user/form.html.eex"},
    {:text, "phx_html/user_index.html.eex", "web/templates/user/index.html.eex"},
    {:text, "phx_html/user_new.html.eex", "web/templates/user/new.html.eex"},
    {:text, "phx_html/user_show.html.eex", "web/templates/user/show.html.eex"}
  ]

  @phx_html_confirm [
    {:text, "password_reset_new.html.eex", "web/templates/password_reset/new.html.eex"},
    {:text, "password_reset_edit.html.eex", "web/templates/password_reset/edit.html.eex"}
  ] ++ @phx_api_confirm

  @doc false
  def run(args) do
    switches = [confirm: :boolean, api: :boolean]
    {opts, _argv, _} = OptionParser.parse(args, switches: switches)

    srcdir = Path.join [Application.app_dir(:openmaize, "priv"),
     "templates", "phoenix"]

    files = @phx ++ case {opts[:api], opts[:confirm]} do
      {true, true} -> @phx_api ++ @phx_api_confirm
      {true, _} -> @phx_api
      {_, true} -> @phx_html ++ @phx_html_confirm
      _ -> @phx_html
    end

    Mix.Openmaize.copy_files(srcdir, files, base: base_module(),
    confirm: opts[:confirm], api: opts[:api])

    Mix.shell.info """

    Please check the generated files. You might need to uncomment certain
    lines and / or change certain details, such as paths or user details.

    Before you use Openmaize, you need to configure Openmaize.
    See the documentation for Openmaize.Config for details.
    """
  end
end
