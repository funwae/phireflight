defmodule PhireFlightWeb.PageController do
  use PhireFlightWeb, :controller

  def home(conn, _params) do
    demo_mode = Application.get_env(:phireflight, :demo_mode, false)
    render(conn, :home, layout: false, demo_mode: demo_mode)
  end
end
