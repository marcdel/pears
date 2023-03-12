defmodule Pears.Persistence.EncryptedBinary do
  use Cloak.Ecto.Binary, vault: Pears.Vault
end
