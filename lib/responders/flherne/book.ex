defmodule MajorTom.Responders.Flherne.Book do
  @moduledoc """
  Reproduce the "nextbook" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Ecto.Query
  require Logger
  alias Hedwig.Message
  alias MajorTom.Repo
  alias MajorTom.Flherne.Book

  @added_responses [
    "Book has been added to The Library.",
  ]


  @usage """
  nextbook -- Randomly choose a book from The Library
  """
  respond ~r/nextbook$/i, msg do
    Repo.one(Ecto.Query.from q in Book,
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "No Books Found?!?! What kind of library is this?!")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  nextbook <search> -- See if we have a book with a similar title
  """
  respond ~r/nextbook\s+(?!add\s)(.+)/i, %Message{matches: %{1 => search}} = msg do
    Repo.one(Ecto.Query.from q in Book,
      where: fragment("msg ILIKE ?", ^"%#{search}%"),
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> case do
      nil -> reply(msg, "The card catalog seems not to have any matches...")
      res -> reply(msg, res.msg)
    end
  end

  @usage """
  nextbook add <quote> -- Record a new book
  """
  respond ~r/nextbook add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Book.changeset(%Book{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _book} <- Repo.insert(cs) do
      reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            reply(msg, "Could not save that for an unknown reason.")
          true -> 
            reply(msg, "An excellent suggestion, but that book is already in The Library.")
        end
    end
  end

  hear ~r/^!nextbook$/i, msg do
    unless MajorTom.IrcRobot.channel_has_user?(msg.room, "LunchBot") do
      Repo.one(Ecto.Query.from q in Book,
        order_by: fragment("RANDOM()"),
        limit: 1
      )
      |> case do
        nil -> maybe_reply(msg, "The card catalog seems not to have any matches...")
        res -> maybe_reply(msg, res.msg)
      end
    end
  end

  hear ~r/^!nextbook add (.+)/i, %Message{matches: %{1 => new_msg}} = msg do
    with cs <- Book.changeset(%Book{}, %{msg: new_msg, submitted_by: msg.user.name}),
         {:ok, _added} <- Repo.insert(cs) do
      maybe_reply(msg, Enum.random(@added_responses))
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        Keyword.get_values(changeset.errors, :msg)
        |> Enum.any?(fn {_desc, opts} -> opts[:constraint] == :unique end)
        |> case do
          false ->
            Logger.error("Could not insert new Book for unknown reason. Msg was: #{inspect(msg)}")
            maybe_reply(msg, "Could not save that for an unknown reason.")
          true -> 
            maybe_reply(msg, "An excellent suggestion, but that book is already in The Library.")
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