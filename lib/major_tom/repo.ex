defmodule MajorTom.Repo do
  use Ecto.Repo,
    otp_app: :major_tom,
    adapter: Ecto.Adapters.Postgres
end
