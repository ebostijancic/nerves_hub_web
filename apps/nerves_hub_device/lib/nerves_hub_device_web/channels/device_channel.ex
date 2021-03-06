defmodule NervesHubDeviceWeb.DeviceChannel do
  use NervesHubDeviceWeb, :channel

  alias NervesHubCore.{Devices, Firmwares, Deployments}
  alias NervesHubDevice.Presence

  @uploader Application.get_env(:nerves_hub_core, :firmware_upload)

  def join("firmware:" <> fw_uuid, _payload, socket) do
    with {:ok, message} <- build_message(socket, fw_uuid) do
      send(self(), {:after_join, message})
      {:ok, message, socket}
    else
      {:error, reply} -> {:error, reply}
    end
  end

  def handle_info({:after_join, %{update_available: update_available}}, socket) do
    {:ok, _} =
      Presence.track(socket, socket.assigns.certificate.device_id, %{
        connected_at: inspect(System.system_time(:seconds)),
        update_available: update_available
      })

    {:noreply, socket}
  end

  def handle_info(
        %{payload: %{device_id: device_id} = payload, event: event},
        %{assigns: %{certificate: %{device_id: device_id}}} = socket
      ) do
    push(socket, event, payload)
    {:noreply, socket}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp build_message(%{assigns: %{certificate: certificate}}, fw_uuid) do
    with {:ok, device} <- Devices.get_device_by_certificate(certificate),
         {:ok, device} <- device_update(device, fw_uuid) do
      Phoenix.PubSub.subscribe(NervesHubWeb.PubSub, "device:#{device.id}")
      send_update_message(device)
    else
      {:error, message} -> {:error, %{reason: message}}
      _ -> {:error, %{reason: :unknown_error}}
    end
  end

  defp build_message(_, _) do
    {:error, %{reason: :no_device_or_org}}
  end

  defp device_update(%Devices.Device{} = device, fw_uuid) do
    with {:ok, firmware} <- Firmwares.get_firmware_by_uuid(device.org, fw_uuid) do
      Devices.update_device(device, %{
        last_known_firmware_id: firmware.id
      })
    else
      _ ->
        {:error, :no_firmware_found}
    end
  end

  defp device_update(_, _), do: {:error, :no_firmware_uuid}

  defp send_update_message(%Devices.Device{} = device) do
    device
    |> Devices.get_eligible_deployments()
    |> do_update_message(device.org)
  end

  defp do_update_message([%Deployments.Deployment{} = deployment | _], org) do
    with {:ok, firmware} <- Firmwares.get_firmware(org, deployment.firmware_id),
         {:ok, url} <- @uploader.download_file(firmware) do
      {:ok, %{update_available: true, firmware_url: url}}
    else
      _ -> {:error, :no_firmware_url}
    end
  end

  defp do_update_message([], _) do
    {:ok, %{update_available: false}}
  end

  defp do_update_message(_, _), do: {:error, :unknown_error}

  def online?(%Devices.Device{last_known_firmware_id: nil}), do: false

  def online?(%Devices.Device{id: id, last_known_firmware: %Firmwares.Firmware{uuid: fw_uuid}}) do
    id = to_string(id)

    "firmware:#{fw_uuid}"
    |> Presence.list()
    |> Map.has_key?(id)
  end

  def online?(%Devices.Device{last_known_firmware_id: nil}), do: false

  def update_pending?(%Devices.Device{
        id: id,
        last_known_firmware: %Firmwares.Firmware{uuid: fw_uuid}
      }) do
    id = to_string(id)

    "firmware:#{fw_uuid}"
    |> Presence.list()
    |> Map.get(id, %{})
    |> Map.get(:metas, [%{}])
    |> List.first()
    |> Map.get(:update_available, false)
  end
end
