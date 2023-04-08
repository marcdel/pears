defmodule Pears.Accounts.TeamNotifier do
  import Swoosh.Email

  alias Pears.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Pears", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(team, url) do
    deliver(team.email, "Confirmation instructions", """

    ==============================

    Hi #{team.email},

    You can confirm your account by visiting the URL below:

    #{url}

    If you didn't create an account with us, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a team password.
  """
  def deliver_reset_password_instructions(team, url) do
    deliver(team.email, "Reset password instructions", """

    ==============================

    Hi #{team.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a team email.
  """
  def deliver_update_email_instructions(team, url) do
    deliver(team.email, "Update email instructions", """

    ==============================

    Hi #{team.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
