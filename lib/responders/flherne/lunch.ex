defmodule MajorTom.Responders.Flherne.Lunch do
  @moduledoc """
  Reproduce the "nextlunch" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.

  TODO: Add last served information to IRC response for random lunch
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Lunch

  @added_responses [
    "Saved Lunch. Sounds yummy!",
    "That sounds terrible. I didn't want to save it, but I did.",
    "Well, I guess I can remember that, if you insist.",
    "Gotcha, added it.",
    "Saved. I might have that myself!",
  ]

  @usage """
  nextlunch -- Randomly selected lunch.
  """
  respond ~r/nextlunch$/i, msg do
    Repo.one(Ecto.Query.from q in Lunch,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "Apparently no lunches have been saved, no wonder I'm so hungry...")
         res ->
           reply(msg, res.msg)
           record_serving(res, msg)
       end
  end

  @usage """
  nextlunch <search> -- Search for a lunch
  """
  respond ~r/nextlunch\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Lunch,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "No similar lunch found.")
         res -> reply(msg, res.msg)
       end
  end

  @usage """
  nextlunch add <quote> -- Add a new type of lunch to the pot.
  """
  respond ~r/nextlunch add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Lunch.changeset(%Lunch{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               Logger.error("Could not insert new Lunch for unknown reason. Msg was: #{inspect(msg)}")
               reply(msg, "Could not save that for an unknown reason. Probably wasn't tasty.")
             true ->
               reply(msg, "I already know that lunch, no sneaky trying to cheat the odds.")
           end
    end
  end

  hear ~r/^!nextlunch$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Lunch,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
           nil -> maybe_reply(msg, "Apparently no lunches have been saved, no wonder I'm so hungry...")
           res ->
             maybe_reply(msg, res.msg)
             record_serving(res, msg)
         end
    end
  end

  hear ~r/^!nextlunch add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Lunch.changeset(%Lunch{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               Logger.error("Could not insert new Lunch for unknown reason. Msg was: #{inspect(msg)}")
               maybe_reply(msg, "Could not save that for an unknown reason. Probably wasn't tasty.")
             true ->
               maybe_reply(msg, "I already know that lunch, no sneaky trying to cheat the odds.")
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

  defp record_serving(lunch, msg) do
    lunch
    |> Lunch.changeset(%{last_served_to: msg.user.name, last_served_at: DateTime.utc_now()})
    |> Repo.update()
    |> case do
      {:error, cs} ->
        Logger.error("Could not update last_served information. Errors: #{inspect(cs.errors)}")
        :error
      {:ok, _res} -> :ok
    end
  end
end