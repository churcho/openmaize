defmodule Openmaize.LogoutTest do
  use ExUnit.Case
  use Plug.Test

  import OpenmaizeJWT.Create
  alias Openmaize.{Authenticate, Logout}

  setup_all do
    {:ok, user_token} = %{id: 1, name: "Raymond Luxury Yacht", role: "user"}
    |> generate_token({0, 7200})

    {:ok, %{user_token: user_token}}
  end

  def call(token, :cookie) do
    conn(:get, "/logout")
    |> put_req_cookie("access_token", token)
    |> fetch_cookies
  end

  def call(token, _) do
    conn(:get, "/logout")
    |> put_req_header("authorization", "Bearer #{token}")
  end

  test "logout with cookie", %{user_token: user_token} do
    conn = call(user_token, :cookie)
    |> Logout.call(&OpenmaizeJWT.LogoutManager.store_jwt/1)
    assert conn.resp_cookies["access_token"] ==
      %{max_age: 0, universal_time: {{1970, 1, 1}, {0, 0, 0}}}
    conn = call(user_token, :cookie)
    |> Authenticate.call(&OpenmaizeJWT.Verify.verify_token/1)
    assert conn.assigns ==  %{current_user: nil}
  end

  test "logout with the token stored in the header", %{user_token: user_token} do
    conn = call(user_token, nil)
    |> Logout.call(&OpenmaizeJWT.LogoutManager.store_jwt/1)
    refute conn.resp_cookies["access_token"]
    conn = call(user_token, nil)
    |> Authenticate.call(&OpenmaizeJWT.Verify.verify_token/1)
    assert conn.assigns ==  %{current_user: nil}
  end

end
