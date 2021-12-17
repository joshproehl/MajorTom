defmodule MajorTom.Responders.Flherne.Misc do
  @moduledoc """
  Reproduce the "nextbook" functions provided by FLHerne's old bot.
  Also prepare to step in to replace that bot if it goes offline.
  """

  use Hedwig.Responder
  require Logger
  alias Hedwig.Message

  @usage """
  lunchmode -- toggle LunchMode
  """
  respond ~r/lunchmode$/i, msg do
    #when in lunchmode *ANY* command is treated as a nextlunch command
    reply(msg, "I can't do that Dave...")
  end

  @usage """
  rocks -- It rocks.
  """
  respond ~r/rocks$/i, msg do
    reply(msg, "https://www.flherne.uk/files/rocks.mp4")
  end

  @usage """
  nextpinecone -- When will orbbfrgg next eat a pinecone?
  """
  respond ~r/nextpinecone$/i, msg do
    reply(msg, "I'm not certain actually, it keeps changing...")
  end

  @usage """
  nextyear -- Does what it says on the box
  """
  respond ~r/nextyear$/i, msg do
    reply(msg, "#{DateTime.utc_now().year+1} (UTC)")
  end

  @usage """
  nextfire
  """
  respond ~r/nextfire$/i, msg do
    # Originally because LunchBot was caught in the OVH datacenter fire and destroyed FLHerne's emails.
    # "Never, hopefully" is the LunchBot response
    reply(msg,"Your kitchen, when you next try and cook pasta. (What am I supposed to do here, predict the future?!)")
  end

  @usage """
  wenhop -- When will starhopper hop?
  """
  respond ~r/wenhop$/i, msg do
    reply(msg,"Starhopper ain't hoppin again unless there's a reaaaaaaally big boom on the pad.")
  end
end