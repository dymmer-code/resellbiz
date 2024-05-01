import Config

config :resellbiz,
  url: System.get_env("URL"),
  reseller_id: System.get_env("RESELLER_ID"),
  api_key: System.get_env("API_KEY"),
  customer_id: System.get_env("CUSTOMER_ID")
