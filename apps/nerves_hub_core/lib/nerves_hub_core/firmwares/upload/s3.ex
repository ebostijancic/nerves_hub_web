defmodule NervesHubCore.Firmwares.Upload.S3 do
  alias ExAws.S3

  @spec upload_file(String.t(), String.t(), integer()) ::
          {:ok, map}
          | {:error, atom()}
  def upload_file(filepath, filename, org_id) do
    bucket = Application.get_env(:nerves_hub_core, __MODULE__)[:bucket]
    s3_path = Path.join(["firmware", Integer.to_string(org_id), filename])

    filepath
    |> S3.Upload.stream_file()
    |> S3.upload(bucket, s3_path)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, %{s3_key: s3_path}}
      error -> error
    end
  end

  @spec download_file(Firmware.t()) ::
          {:ok, String.t()}
          | {:error, String.t()}
  def download_file(firmware) do
    s3_key = firmware.upload_metadata["s3_key"]
    bucket = Application.get_env(:nerves_hub_core, __MODULE__)[:bucket]

    ExAws.Config.new(:s3)
    |> S3.presigned_url(:get, bucket, s3_key, expires_in: 600)
    |> case do
      {:ok, url} ->
        {:ok, url}

      error ->
        error
    end
  end

  @spec delete_file(Firmware.t()) ::
          {:ok, any()}
          | {:error, any()}
  def delete_file(firmware) do
    s3_key = firmware.upload_metadata["s3_key"]
    bucket = Application.get_env(:nerves_hub_core, __MODULE__)[:bucket]

    S3.delete_object(bucket, s3_key)
  end
end
