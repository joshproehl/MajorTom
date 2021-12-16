defmodule MajorTom.Responders.Flherne.Banned do
  @moduledoc """
  Reproduce the "banned" function provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Banned

  @added_responses [
    "BanHammer has been dropped.",
    "Theeeeeeey're outta here!",
  ]


  @usage """
  banlist -- Randomly chosen banned username
  """
  respond ~r/banlist$/i, msg do
    Repo.one(Ecto.Query.from q in Banned,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No banned users found. That seems good, but unlikely.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  banlist <search> -- See if we have a banned that matches
  """
  respond ~r/banlist\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Banned,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No matching banned user found.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  banlist add <quote> -- Record a new banned user
  """
  respond ~r/banlist add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Banned.changeset(%Banned{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _banned} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            reply(msg, "Could not save that for an unknown reason.")
          true -> 
            reply(msg, "That user is already banned. Doing it twice doesn't make it stick any harder.")
        end
    end
  end

  hear ~r/^!banlist$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Banned,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "No banned users found. That seems good, but unlikely.")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!banlist add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Banned.changeset(%Banned{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Banned user for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason.")
          true -> 
            maybe_reply(msg, "That user is already banned. Doing it twice doesn't make it stick any harder.")
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