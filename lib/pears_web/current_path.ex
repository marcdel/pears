defmodule PearsWeb.CurrentPath do
  def on_mount(:get_current_path, _params, _session, socket),
    do:
      {:cont,
       Phoenix.LiveView.attach_hook(
         socket,
         :get_current_path,
         :handle_params,
         &get_current_path/3
       )}

  defp get_current_path(_params, url, socket),
    do: {:cont, Phoenix.Component.assign(socket, :current_path, URI.parse(url) |> Map.get(:path))}
end
