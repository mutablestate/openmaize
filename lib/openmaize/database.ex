defmodule Openmaize.Database do
  @moduledoc """
  Functions that are used to access the database.
  """

  import Ecto.{Changeset, Query}
  alias Openmaize.{Config, Password}

  @doc """
  Hash the password and add it to the user model or changeset.

  Before the password is hashed, it is checked to make sure that
  it is not too weak. See the documentation for the Openmaize.Password
  module for more information about the options available.

  This function will return a changeset. If there are any errors, they
  will be added to the changeset.

  Comeonin.Bcrypt is the default hashing function, but this can be changed to
  Comeonin.Pbkdf2, or any other algorithm, by setting the Config.crypto_mod value.
  """
  def add_password_hash(user, params) do
    (params[:password] || params["password"])
    |> Password.valid_password?(Config.password_min_len)
    |> add_hash_changeset(user)
  end

  @doc """
  Add a confirmation token to the user model or changeset.

  Add the following three entries to your user schema:

      field :confirmation_token, :string
      field :confirmation_sent_at, Ecto.DateTime
      field :confirmed_at, Ecto.DateTime

  ## Examples

  In the following example, the 'add_confirm_token' function is called with
  a key generated by 'Openmaize.ConfirmEmail.gen_token_link':

      changeset |> Openmaize.Database.add_confirm_token(key)

  """
  def add_confirm_token(user, key) do
    change(user, %{confirmation_token: key,
      confirmation_sent_at: Ecto.DateTime.utc})
  end

  @doc """
  Add a reset token to the user model or changeset.

  Add the following two entries to your user schema:

      field :reset_token, :string
      field :reset_sent_at, Ecto.DateTime

  As with 'add_confirm_token', the function 'Openmaize.ConfirmEmail.gen_token_link'
  can be used to generate the token and link.
  """
  def add_reset_token(user, key) do
    change(user, %{reset_token: key, reset_sent_at: Ecto.DateTime.utc})
  end

  @doc """
  Change the 'confirmed_at' value in the database to the current time.
  """
  def user_confirmed(user, repo) do
    change(user, %{confirmed_at: Ecto.DateTime.utc})
    |> repo.update
  end

  @doc """
  Add the password hash for the new password to the database.

  If the update is successful, the reset_token and reset_sent_at
  values will be set to nil.
  """
  def password_reset(user, password, repo) do
    Password.valid_password?(password, Config.password_min_len)
    |> reset_update_repo(user, repo)
  end

  @doc """
  Get user and lock the database.

  This is used when updating the HOTP token.
  """
  def get_user_with_lock(repo, user_model, id) do
    from(u in user_model, where: u.id == ^id, lock: "FOR UPDATE")
    |> repo.one!
  end

  @doc """
  Update the database with the new value for otp_last.

  This is used with both HOTP and TOTP tokens.
  """
  def update_otp({_, false}, _), do: {:error, "invalid one-time password"}
  def update_otp({%{otp_last: otp_last} = user, last}, repo) when last > otp_last do
    change(user, %{otp_last: last}) |> repo.update!
  end
  def update_otp(_, _), do: {:error, "invalid user-identifier"}

  @doc """
  Function used to check if a token has expired.
  """
  def check_time(nil, _), do: false
  def check_time(sent_at, valid_secs) do
    (sent_at |> Ecto.DateTime.to_erl
     |> :calendar.datetime_to_gregorian_seconds) + valid_secs >
    (:calendar.universal_time |> :calendar.datetime_to_gregorian_seconds)
  end

  defp add_hash_changeset({:ok, password}, user) do
    change(user, %{Config.hash_name =>
      Config.crypto_mod.hashpwsalt(password)})
  end
  defp add_hash_changeset({:error, message}, user) do
    change(user, %{password: ""}) |> add_error(:password, message)
  end

  defp reset_update_repo({:ok, password}, user, repo) do
    repo.transaction(fn ->
      user = change(user, %{Config.hash_name =>
        Config.crypto_mod.hashpwsalt(password)})
      |> repo.update!

      change(user, %{reset_token: nil, reset_sent_at: nil})
      |> repo.update!
    end)
  end
  defp reset_update_repo({:error, message}, _user, _repo) do
    {:error, message}
  end
end
