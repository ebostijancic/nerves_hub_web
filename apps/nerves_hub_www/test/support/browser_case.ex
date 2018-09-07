defmodule NervesHubWWWWeb.ConnCase.Browser do
  @moduledoc """
  conn case for browser related tests
  """
  use ExUnit.CaseTemplate

  alias NervesHubCore.Accounts

  using do
    quote do
      use NervesHubWWWWeb.ConnCase
      import Plug.Test

      setup do
        %{
          org: org,
          org_key: org_key,
          user: user,
          firmware: firmware,
          deployment: deployment,
          product: product
        } = NervesHubCore.Fixtures.standard_fixture()

        {:ok, org_with_org_keys} = org.id |> Accounts.get_org_with_org_keys()

        conn =
          build_conn()
          |> Map.put(:assigns, %{current_org: org_with_org_keys, user: user})
          |> init_test_session(%{
            "auth_user_id" => user.id,
            "current_org_id" => org.id
          })

        %{conn: conn, current_user: user, current_org: org, org_key: org_key}
      end
    end
  end
end
