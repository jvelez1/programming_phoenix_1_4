defmodule Rumbl.Accounts do
  @moduledoc """
    The account context
  """
  import Ecto.Query
  alias Rumbl.Repo
  alias Rumbl.Accounts.User

  def change_registration(%User{} = user, params) do
    User.registration_changeset(user, params)
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  def list_users do
    Repo.all(User)
  end

  def get_user(id) do
    Repo.get(User, id)
  end

  def get_user!(id) do
    Repo.get!(User, id)
  end

  def get_user_by(params) do
    Repo.get_by(User, params)
  end

  def list_users_by_ids(ids) do
    Repo.all(
      from u in User, where: u.id in ^ids
    )
  end

  def authenticate_by_username_and_pass(user_name, given_pass) do
    user = get_user_by(username: user_name)

    cond do
      user && Pbkdf2.verify_pass(given_pass, user.password_hash) ->
        {:ok, user}
      user ->
        {:error, :unauthorized }
      true ->
        Pbkdf2.no_user_verify()
        {:error, :not_found}
    end
  end
end
