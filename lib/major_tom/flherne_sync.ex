defmodule MajorTom.FlherneSync do
  @moduledoc """
  Fetch the latest content from FLHerne's version of the bot to make sure we're in sync.
  """

  use GenServer
  require Logger
  alias MajorTom.Flherne.{Bankrupt,Banned,Book,Colloid,Frog,Lunch,Mission,Outcome,Stupid}
  alias MajorTom.FlherneSync
  alias MajorTom.Repo

  @update_interval 86_400_000 # 1000 * 60 * 60 * 24, sync once an hour day, just in case we missed anything
  @req_headers []
  @req_options []

  @doc """
  Manually trigger a sync of all content from FLHerne's server
  """
  def sync_all() do
    GenServer.cast(__MODULE__, {:sync, :all})
  end

  def http_adapter, do: Application.get_env(:major_tom, :flherne_sync_http_adapter)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    Logger.debug("Initializing FLHerneSync genserver")
    # After initializing the GenServer do an initial fetch of the various data files,
    # this is disabled by default in the dev mode config so we don't slam his server every restart.
    if Application.get_env(:major_tom, :enable_flherne_sync), do: FlherneSync.sync_all()
    {:ok, %{latest: []}}
  end

  def handle_cast({:sync, :all}, state) do
    Process.send_after(self(), {:sync, :stupid}, 2_000)
    Process.send_after(self(), {:sync, :frogs}, 4_000)
    Process.send_after(self(), {:sync, :lunches}, 6_000)
    Process.send_after(self(), {:sync, :outcomes}, 8_000)
    Process.send_after(self(), {:sync, :missions}, 10_000)
    Process.send_after(self(), {:sync, :colloids}, 12_000)
    Process.send_after(self(), {:sync, :books}, 14_000)
    Process.send_after(self(), {:sync, :banned}, 16_000)
    Process.send_after(self(), {:sync, :bankrupt}, 18_000)
    {:noreply, state}
  end

  def handle_info({:sync, type}, state) do
    Logger.debug("syncing #{type}.txt from FLHerne's server")
    with {:ok, res} <- fetch_txt_file(type)
    do
      process_response(type, res)
    else
      {:error, _} -> nil
    end
    Process.send_after(self(), {:fetch, type}, @update_interval)
    {:noreply, Map.put(state, {:last_sync, type}, DateTime.utc_now())}
  end

  # EXAMPLE
  def handle_call({:get_latest}, _from, state) do
    {:reply, Map.fetch(state, :latest), state}
  end

  @spec fetch_txt_file(String.t()) :: String.t()
  def fetch_txt_file(type) do
    with {:ok, %HTTPoison.Response{status_code: 200, body: result_body}} <- http_adapter().get("https://www.flherne.uk/hacks/#{type}.txt", @req_headers, @req_options)
    do
      Logger.debug("Got result body for #{type}.txt successfully.")
      {:ok, result_body}
    else
      {:ok, %HTTPoison.Response{status_code: code}} ->
        Logger.error("HTTP Request to flherne.uk/hacks/#{type}.txt return non-200 response code (#{code}), so no result was returned.")
        {:error, ""}
      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP Request to flherne.uk/hacks/#{type}.txt returned an error: #{reason}")
        {:error, ""}
      _ -> 
        Logger.error("UNKNOWN ERROR making request to flherne.uk/hacks/#{type}.txt")
        {:error, ""}
    end
  end


  def process_response(type, res) when type == :bankrupt do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_bankruptcy(line) end)
  end
  def process_response(type, res) when type == :banned do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_banned(line) end)
  end
  def process_response(type, res) when type == :books do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_book(line) end)
  end
  def process_response(type, res) when type == :colloids do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_colloid(line) end)
  end
  def process_response(type, res) when type == :stupid do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_stupid(line) end)
  end
  def process_response(type, res) when type == :frogs do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_frog(line) end)
  end
  def process_response(type, res) when type == :lunches do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_lunch(line) end)
  end
  def process_response(type, res) when type == :outcomes do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_outcome(line) end)
  end
  def process_response(type, res) when type == :missions do
    String.split(res, ~r{\r\n|\r|\n})
    |> Enum.map(fn line -> insert_or_ignore_mission(line) end)
  end
  def process_response(type, _res) do
    Logger.error("Tried to process a response for a type (#{type}) that didn't exist!")
  end

  def insert_or_ignore_stupid(stupid_msg) do
    %Stupid{}
    |> MajorTom.Flherne.Stupid.changeset(%{msg: stupid_msg})
    |> Repo.insert()
    |> case do
      {:ok, _stupid} -> :ok
      {:error, _} -> :error
    end
  end

  def insert_or_ignore_frog(frog) do
    %Frog{}
    |> MajorTom.Flherne.Frog.changeset(%{msg: frog})
    |> Repo.insert()
    |> case do
      {:ok, _frog} -> :ok
      {:error, _} -> :error
    end
  end

  def insert_or_ignore_lunch(lunch) do
    %Lunch{}
    |> Lunch.changeset(%{msg: lunch})
    |> Repo.insert()
    |> case do
         {:ok, _lunch} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_outcome(outcome) do
    %Outcome{}
    |> Outcome.changeset(%{msg: outcome})
    |> Repo.insert()
    |> case do
         {:ok, _outcome} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_mission(mission) do
    %Mission{}
    |> Mission.changeset(%{msg: mission})
    |> Repo.insert()
    |> case do
         {:ok, _mission} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_colloid(colloid) do
    %Colloid{}
    |> Colloid.changeset(%{msg: colloid})
    |> Repo.insert()
    |> case do
         {:ok, _colloid} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_book(book) do
    %Book{}
    |> Book.changeset(%{msg: book})
    |> Repo.insert()
    |> case do
         {:ok, _book} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_banned(banned) do
    %Banned{}
    |> Banned.changeset(%{msg: banned})
    |> Repo.insert()
    |> case do
         {:ok, _banned} -> :ok
         {:error, _} -> :error
       end
  end

  def insert_or_ignore_bankruptcy(bankruptcy) do
    %Bankrupt{}
    |> Bankrupt.changeset(%{msg: bankruptcy})
    |> Repo.insert()
    |> case do
         {:ok, _bankrupt} -> :ok
         {:error, _} -> :error
       end
  end
end