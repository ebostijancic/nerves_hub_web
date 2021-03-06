defmodule NervesHubAPIWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use NervesHubAPIWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(NervesHubAPIWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(NervesHubAPIWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, reason}) when is_atom(reason) do
    conn
    |> put_resp_content_type("application/json")
    |> put_status(400)
    |> put_view(NervesHubAPIWeb.ErrorView)
    |> send_resp(400, Jason.encode!(%{status: reason}))
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(500)
    |> put_view(NervesHubAPIWeb.ErrorView)
    |> render(:"500", %{reason: reason})
  end
end
