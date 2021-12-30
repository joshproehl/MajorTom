defmodule MajorTomWeb.FlherneLive.Index do
  use MajorTomWeb, :live_view
  require Ecto.Query
  alias MajorTom.Repo
  alias MajorTom.Flherne.Stupid


  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"search_field" => %{"term" => ""}}, socket) do
    {:noreply, push_patch(socket, to: Routes.flherne_index_path(socket, :show, socket.assigns.type), replace: true)}
  end
  def handle_event("search", %{"search_field" => %{"term" => term}}, socket) do
    items = case socket.assigns.type do
      :stupid -> Repo.all(Stupid.search(term))
      _ -> []
    end
    {:noreply, assign(socket, :items, items)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Choose FLHerne object type")
    |> assign(:type, nil)
    |> assign(:items, nil)
  end

  defp apply_action(socket, :show, %{"type" => "stupid"} = params) do
    count = case params["count"] do
      count when is_nil(count) -> 10
      count -> count
    end

    items = cond do
      is_nil(params["e"]) and is_nil(params["s"]) -> Repo.all(Stupid.all() |> Ecto.Query.limit(^count))
      is_nil(params["e"]) -> Repo.all(Stupid.all() |> Stupid.after_id(params["s"]) |> Ecto.Query.limit(^count))
      is_nil(params["s"]) -> Repo.all(Stupid.all() |> Stupid.before_id(params["e"]) |> Ecto.Query.limit(^count))
    end

    # If we try to go too far to either side, just show the default "latest" result rather than nothing.
    items = case Enum.count(items) do
      0 -> Repo.all(Stupid.all() |> Ecto.Query.limit(^count))
      _ -> items
    end

    socket
    |> assign(:type, :stupid)
    |> assign(:page_title, "Stupid Quotes")
    |> assign(:items, items)
    |> assign(:count, count)
    |> assign(:last_id, id_or_nil(List.first(items)))
    |> assign(:first_id, id_or_nil(List.last(items)))
  end

  defp apply_action(socket, :show, %{"type" => unknown_type}) do
    socket
    |> assign(:type, :unknown)
    |> assign(:page_title, "Unknown Type")
    |> assign(:items, [])
    |> assign(:count, 50)
    |> assign(:last_id, 0)
    |> assign(:first_id, 0)
  end

  defp id_or_nil(item) do
    case item do
      item when is_nil(item) -> nil
      item -> item.id
    end
  end
end