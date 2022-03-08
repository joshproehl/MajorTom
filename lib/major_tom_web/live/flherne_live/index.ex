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
  def handle_params(params, _url, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <h2>FLHerne's Lunchbot, a staple of #spacex, offers the following features:</h2>

      <div>
        <h3>Stupid Quotes</h3>
      </div>

      <div>
        <h3>Frogs</h3>
      </div>
    """
  end

end