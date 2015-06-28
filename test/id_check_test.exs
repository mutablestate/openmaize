defmodule Openmaize.IdCheckTest do
  use ExUnit.Case
  use Plug.Test

  alias Openmaize.IdCheck

  @user %{id: 1, name: "Raymond Luxury Yacht", role: "user"}

  def call(conn, path, show) do
    assign(conn, :current_user, @user)
    |> put_private(:openmaize_vars, %{path: path, match: "/users"})
    |> IdCheck.call([show: show])
  end

  test "user with correct id can edit" do
    path = "/users/1/edit"
    conn = conn(:get, path) |> call(path, true) |> send_resp(200, "")
    assert conn.status == 200
  end

  test "user with correct id can show" do
    path = "/users/1"
    conn = conn(:get, path) |> call(path, true) |> send_resp(200, "")
    assert conn.status == 200
  end

  test "user with wrong id, but start of id is the same" do
    path = "/users/10/edit"
    conn = conn(:get, path) |> call(path, true)
    assert List.keyfind(conn.resp_headers, "location", 0) ==
    {"location", "http://www.example.com/users"}
    assert conn.status == 302
  end

  test "user with wrong id -- cannot edit" do
    path = "/users/3/edit"
    conn = conn(:get, path) |> call(path, true)
    assert List.keyfind(conn.resp_headers, "location", 0) ==
    {"location", "http://www.example.com/users"}
    assert conn.status == 302
  end

  test "user with wrong id -- cannot show" do
    path = "/users/3"
    conn = conn(:get, path) |> call(path, false)
    assert List.keyfind(conn.resp_headers, "location", 0) ==
    {"location", "http://www.example.com/users"}
    assert conn.status == 302
  end

end
