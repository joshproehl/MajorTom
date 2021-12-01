defmodule MajorTomWeb.PageController do
  use MajorTomWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
