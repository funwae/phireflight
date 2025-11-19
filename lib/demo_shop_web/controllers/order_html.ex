defmodule DemoShopWeb.OrderHTML do
  use PhireFlightWeb, :html

  import PhireFlightWeb.Components.StatusBadge

  embed_templates "order_html/*"
end

