defmodule NervesHubWWWWeb.LayoutView do
  use NervesHubWWWWeb, :view

  alias NervesHubCore.Accounts.User

  def navigation_links(conn) do
    [
      {"Products", product_path(conn, :index)},
      {"All Devices", device_path(conn, :index)}
    ]
  end

  def logged_in?(%{assigns: %{user: %User{}}}), do: true
  def logged_in?(_), do: false

  def logo_href(conn) do
    if logged_in?(conn) do
      dashboard_path(conn, :index)
    else
      home_path(conn, :index)
    end
  end

  def permit_uninvited_signups do
    Application.get_env(:nerves_hub_www, NervesHubWWWWeb.AccountController)[:allow_signups]
  end
end
