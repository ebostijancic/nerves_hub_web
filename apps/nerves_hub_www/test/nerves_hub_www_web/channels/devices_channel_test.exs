defmodule NervesHubWWWWeb.DevicesChannelTest do
  use NervesHubWWWWeb.ChannelCase
  alias NervesHubCore.Fixtures
  alias NervesHubDevice.Presence

  setup do
    %{
      user: %{id: user_id, orgs: [%{id: org_id} | _]},
      device: %{id: device_id},
      firmware: %{uuid: firmware_uuid},
      device_certificate: device_certificate
    } = Fixtures.very_fixture()

    device_socket =
      socket(NervesHubDeviceWeb.UserSocket, "device_socket:#{device_id}", %{
        certificate: device_certificate
      })

    spawn_link(fn ->
      {:ok, _, _} =
        device_socket
        |> Map.put(:endpoint, NervesHubDeviceWeb.Endpoint)
        |> subscribe_and_join(NervesHubDeviceWeb.DeviceChannel, "firmware:#{firmware_uuid}")
    end)

    {:ok, _, socket} =
      NervesHubWWWWeb.UserSocket
      |> socket("user_socket:#{user_id}", %{auth_user_id: user_id})
      |> subscribe_and_join(NervesHubWWWWeb.DevicesChannel, "devices:#{org_id}")

    {:ok, socket: socket, device_socket: device_socket}
  end

  test "can see device within authenticated org", %{socket: socket, device_socket: device_socket} do
    assert_push("presence_state", %{})
    assert_push("presence_state", %{})
    device_socket |> Presence.list() |> IO.inspect(label: :my_pres1)
    socket |> Presence.list() |> IO.inspect(label: :my_pres2)
    assert_push("presence_state", %{"payload" => "data"})
    assert false
  end
end
