import os
import smtplib
from email.message import EmailMessage


def send_password_reset_email(to_email: str, reset_link: str):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")

    if not smtp_host or not smtp_user or not smtp_password:
        raise ValueError("Brakuje konfiguracji SMTP w pliku .env")

    reset_token = reset_link.split("token=")[-1]

    msg = EmailMessage()
    msg["Subject"] = "Reset hasła - RaccoonTravel"
    msg["From"] = smtp_user
    msg["To"] = to_email

    msg.set_content(
        f"""
Cześć!

Otrzymaliśmy prośbę o zresetowanie hasła do konta RaccoonTravel.

Aby ustawić nowe hasło, skopiuj poniższy token resetujący i wklej go w aplikacji na ekranie zmiany hasła:

{reset_token}

Token jest ważny przez 30 minut.

Jeśli to nie Ty wysłałaś prośbę o zmianę hasła, zignoruj tę wiadomość.
"""
    )

    with smtplib.SMTP(smtp_host, smtp_port) as server:
        server.starttls()
        server.login(smtp_user, smtp_password)
        server.send_message(msg)