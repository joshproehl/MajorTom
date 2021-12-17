defmodule MajorTom.Responders.Flherne.Bankrupt do
  @moduledoc """
  Reproduce the "nextbankruptcy" function provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Bankrupt

  @added_responses [
    "Saved. I guess we'll see...",
    "Saved. Seems likely to me."
  ]


  @usage """
  nextbankruptcy -- Randomly choose a company that is expected to go bankrupt.
  """
  respond ~r/nextbankruptcy$/i, msg do
    Repo.one(Ecto.Query.from q in Bankrupt,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No future bankrupt companies have been saved.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  nextbankruptcy <search> -- See if we have an impending bankruptcy that matches
  """
  respond ~r/nextbankruptcy\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Bankrupt,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No matching upcoming bankruptcy user found.")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  nextbankruptcy add <quote> -- Record a company that you expect to go bankrupt
  """
  respond ~r/nextbankruptcy add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Bankrupt.changeset(%Bankrupt{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _bankrupt} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            reply(msg, "Could not save that for an unknown reason.")
          true -> 
            reply(msg, "Yeah, we already know they're on the way out.")
        end
    end
  end

  hear ~r/^!nextbankruptcy$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Bankrupt,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "No future bankrupt companies have been saved.")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!nextbankruptcy add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Bankrupt.changeset(%Bankrupt{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Bankruptcy user for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason.")
          true -> 
            maybe_reply(msg, "Yeah, we already know that company is on the way out.")
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