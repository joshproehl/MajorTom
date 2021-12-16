defmodule MajorTom.Responders.Flherne.Mission do
  @moduledoc """
  Reproduce the "mission" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Mission

  @added_responses [
    "Roger, mission saved.",
  ]

  @usage """
  mission -- Randomly chosen mission
  """
  respond ~r/mission$/i, msg do
    Repo.one(Ecto.Query.from q in Mission,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "Failure to launch, no missions found!")
         res -> reply(msg, res.msg)
       end
  end

  @usage """
  mission <search> -- See if we have a mission similar to your request
  """
  respond ~r/mission\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Mission,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "No matching mission found.")
         res -> reply(msg, res.msg)
       end
  end

  @usage """
  mission add <quote> -- Record a new mission
  """
  respond ~r/mission add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Mission.changeset(%Mission{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _mission} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               reply(msg, "Could not save that for an unknown reason.")
             true ->
               reply(msg, "That mission is already being planned.")
           end
    end
  end

  hear ~r/^!mission$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Mission,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
           nil -> maybe_reply(msg, "Failure to launch, no missions found!")
           res -> maybe_reply(msg, res.msg)
         end
    end
  end

  hear ~r/^!mission add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Mission.changeset(%Mission{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               Logger.error("Could not insert new Mission for unknown reason. Msg was: #{inspect(msg)}")
               maybe_reply(msg, "Could not save that for an unknown reason.")
             true ->
               maybe_reply(msg, "That mission is already being planned.")
           end
    end
  end

  defp maybe_reply(msg, text) do
    case MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      true -> nil
      false -> reply msg, text
    end
    :ok
  end
end