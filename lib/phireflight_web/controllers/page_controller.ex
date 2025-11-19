defmodule PhireFlightWeb.PageController do
  use PhireFlightWeb, :controller

  def home(conn, _params) do
    render(conn, :home, layout: false)
  end
end
