defmodule MajorTom.Responders.Flherne.Frog do
  @moduledoc """
  Reproduce the "nextfrog" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Frog

  @added_responses [
    "Ribbit. (Saved frog!)",
  ]


  @usage """
  hedwig: frog -- Randomly chosen frog
  """
  respond ~r/nextfrog$/i, msg do
    Repo.one(Ecto.Query.from q in Frog,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No Frogs Found! [ Sad croaking noises ]")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  hedwig: frog <search> -- See if we have a frog that matches
  """
  respond ~r/nextfrog\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Frog,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No matching frog found. (https://i.imgur.com/eUfWBRi.jpeg)")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  hedwig: frog add <quote> -- Record a new frog 
  """
  respond ~r/nextfrog add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Frog.changeset(%Frog{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _frog} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            reply(msg, "Could not save that for an unknown reason.")
          true -> 
            reply(msg, "I've already met that frog, but thanks!")
        end
    end
  end

  hear ~r/^!nextfrog$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Frog,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "No frogs found! [ Sad croaking noises ]")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!nextfrog add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Frog.changeset(%Frog{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Frog for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason.")
          true -> 
            maybe_reply(msg, "I've already met that frog, but thanks!")
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
