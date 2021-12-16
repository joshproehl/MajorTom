defmodule MajorTom.Responders.Flherne.Outcome do
  @moduledoc """
  Reproduce the "outcome" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Outcome

  @added_responses [
    "Magic 8-ball says: Outcome Saved.",
  ]

  @usage """
  outcome -- Randomly chosen outcome
  """
  respond ~r/outcome$/i, msg do
    Repo.one(Ecto.Query.from q in Outcome,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "No outcomes found! What happened to entropy?!")
         res -> reply(msg, res.msg)
       end
  end

  @usage """
  outcome <search> -- See if we have an outcome that matches
  """
  respond ~r/outcome\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Outcome,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
         nil -> reply(msg, "No matching outcome found.")
         res -> reply(msg, res.msg)
       end
  end

  @usage """
  outcome add <quote> -- Record a possible outcome
  """
  respond ~r/outcome add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Outcome.changeset(%Outcome{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _outcome} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               reply(msg, "Could not save that for an unknown reason.")
             true ->
               reply(msg, "That is already a known outcome.")
           end
    end
  end

  hear ~r/^!outcome$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Outcome,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
           nil -> maybe_reply(msg, "No outcomes found! What happened to entropy?!")
           res -> maybe_reply(msg, res.msg)
         end
    end
  end

  hear ~r/^!outcome add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Outcome.changeset(%Outcome{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
             false ->
               Logger.error("Could not insert new Outcome for unknown reason. Msg was: #{inspect(msg)}")
               maybe_reply(msg, "Could not save that for an unknown reason.")
             true ->
               maybe_reply(msg, "That is already a known outcome.")
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