defmodule MajorTom.Responders.Flherne do
  @moduledoc """
  Reproduce the Bot functions provided by FLHerne's old bot.
  """

  use Hedwig.Responder

  @usage """
  """
  respond ~r/stupid$/i, msg do
    reply msg, "That's dumb."
  end
end
