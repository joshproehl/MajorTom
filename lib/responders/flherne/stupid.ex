defmodule MajorTom.Responders.Flherne.Stupid do
  @moduledoc """
  Reproduce the "stupid quote" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Stupid

  @added_responses [
    "Definitely stupid! I'll remember that.",
    "Noted.",
    "Yikes!",
    "Gotcha, added it.",
  ]


  @usage """
  hedwig: stupid -- Randomly chosen dose of stupidity
  """
  respond ~r/stupid$/i, msg do
    Repo.one(Ecto.Query.from q in Stupid,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "Apparently nothing stupid has been saved, which seems stupid.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  hedwig: stupid <search> -- Search the Book of Stupidity for your search term and returns a random matching item.
  """
  respond ~r/stupid\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Stupid,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No match found. Maybe you're the stupid one?")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  hedwig: stupid add <quote> -- Add to the Book of Stupidity.
  """
  respond ~r/stupid add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Stupid.changeset(%Stupid{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Stupid quote for unknown reason. Msg was: #{inspect(msg)}")
            reply(msg, "Could not save that for an unknown reason. Guess I'm the stupid one.")
          true -> 
            reply(msg, "I've already heard that one stupid.")
        end
    end
  end

  hear ~r/^!stupid$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Stupid,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "Apparently nothing stupid has been saved, which seems stupid.")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!stupid add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    Logger.debug("Responder firing for \"!stupid add\"")
    with cs <- Stupid.changeset(%Stupid{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Stupid quote for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason. Guess I'm the stupid one.")
          true -> 
            maybe_reply(msg, "I've already heard that one stupid.")
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
