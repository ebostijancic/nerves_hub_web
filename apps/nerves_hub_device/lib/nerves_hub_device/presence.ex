defmodule NervesHubDevice.Presence do
  use Phoenix.Presence,
    otp_app: :nerves_hub_device,
    pubsub_server: NervesHubWeb.PubSub

  alias NervesHubCore.{Devices.Device, Firmwares.Firmware}
  alias NervesHubDevice.Presence

  def fetch("devices:" <> _, entries) do
    Enum.reduce(entries, %{}, fn
      {key, %{metas: [%{last_known_firmware_id: nil}]} = val}, acc ->
        Map.put(acc, key, Map.put(val, :status, "offline"))

      {key, %{metas: [%{last_known_firmware_id: _}]} = val}, acc ->
        Map.put(acc, key, Map.put(val, :status, "online"))

      _, acc ->
        acc
    end)
  end

  def fetch(_, entries), do: entries

  def device_status(%Device{id: device_id, last_known_firmware: %Firmware{uuid: fw_uuid}}) do
    "firmware:#{fw_uuid}"
    |> Presence.list()
    |> Map.get("#{device_id}")
    |> case do
      %{metas: [%{update_available: true}]} -> "update pending"
      _ -> "online"
    end
  end

  def device_status(_), do: "offline"
end
