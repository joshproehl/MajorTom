defmodule MajorTom.Responders.Flherne.Colloid do
  @moduledoc """
  Reproduce the "colloid" and "colloid²" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Colloid

  @added_responses [
    "Colloid Collected Successfully",
  ]

  @usage """
  colloid -- Randomly chosen colloid
  """
  respond ~r/colloid$/i, msg do
    Repo.one(Ecto.Query.from q in Colloid,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "Nothing colloidal found.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  colloid <search> -- See if we have a similar colloid
  """
  respond ~r/colloid\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Colloid,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No matching colloid found.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  colloid add <quote> -- Record a new colloid
  """
  respond ~r/colloid add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Colloid.changeset(%Colloid{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _colloid} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            reply(msg, "Could not save that for an unknown reason.")
          true -> 
            reply(msg, "Yes, I know about that one, thanks.")
        end
    end
  end

  hear ~r/^!colloid$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Colloid,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "No matching colloid found.")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!colloid add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Colloid.changeset(%Colloid{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Colloid for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason.")
          true -> 
            maybe_reply(msg, "Yes, I know about that one, thanks.")
        end
    end
  end

  respond ~r/colloid²$/i, msg do
    reply(msg, "What's this supposed to do?")
  end

  defp maybe_reply(msg, text) do
    case MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      true -> nil
      false -> reply msg, text
    end
    :ok
  end
end