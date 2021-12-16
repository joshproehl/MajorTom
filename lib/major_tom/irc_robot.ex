defmodule MajorTom.IrcRobot do
  use Hedwig.Robot, otp_app: :major_tom
  require Logger

  #####
  # Public API
  #####

  @doc """
  Return the PID for this robot
  """
  @spec get_pid() :: pid()
  def get_pid(), do: :global.whereis_name(Application.get_env(:major_tom, MajorTom.IrcRobot)[:name])

  @doc """
  Return the PID for the ExIRC adapter"
  """
  @spec get_client_pid() :: pid()
  def get_client_pid() do 
    %{adapter: adapter_pid} = :sys.get_state(get_pid())
    {_adapter_pid, _apadpter_opts, client_pid} = :sys.get_state(adapter_pid)
    client_pid
  end

  @doc """
  Determine if the given user exists in the given channel.
  """
  @spec channel_has_user?(String.t(), String.t()) :: boolean()
  def channel_has_user?(channel, username) do
    ExIRC.Client.channel_has_user?(get_client_pid(), channel, username)
  end


  #####
  # allowedoverrides from Hedwig.Robot
  #####
  def handle_connect(%{name: name} = state) do
    if :undefined == :global.whereis_name(name) do
      :yes = :global.register_name(name, self())
    end

    {:ok, state}
  end

  def handle_disconnect(_reason, state) do
    {:reconnect, 5000, state}
  end

  def handle_in(%Hedwig.Message{} = msg, state) do
    {:dispatch, msg, state}
  end

  def handle_in(_msg, state) do
    {:noreply, state}
  end

end
