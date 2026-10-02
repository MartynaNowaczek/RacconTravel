import os
import smtplib

from email.message import EmailMessage

from dotenv import load_dotenv


load_dotenv()


def send_friend_invitation_email(
    receiver_email: str,
    sender_name: str,
    invitation_code: str,
):
    smtp_host = os.getenv("SMTP_HOST")
    smtp_port = int(
        os.getenv(
            "SMTP_PORT",
            "587",
        )
    )

    smtp_user = os.getenv("SMTP_USER")
    smtp_password = os.getenv("SMTP_PASSWORD")

    if not smtp_host:
        raise RuntimeError(
            "Brak SMTP_HOST."
        )

    if not smtp_user:
        raise RuntimeError(
            "Brak SMTP_USER."
        )

    if not smtp_password:
        raise RuntimeError(
            "Brak SMTP_PASSWORD."
        )

    message = EmailMessage()

    message["Subject"] = (
        "Zaproszenie do znajomych - RaccoonTravel"
    )

    message["From"] = smtp_user
    message["To"] = receiver_email

    message.set_content(
        f"""
Cześć!

Użytkownik {sender_name} chce dodać Cię do znajomych w aplikacji RaccoonTravel.

Twój kod zaproszenia:

{invitation_code}

Aby zaakceptować zaproszenie:

1. Otwórz aplikację RaccoonTravel.
2. Przejdź do swojego profilu.
3. Kliknij przycisk dodawania znajomego.
4. Wybierz opcję "Mam kod zaproszenia".
5. Wpisz kod podany powyżej.

Kod jest ważny przez 7 dni.

RaccoonTravel
"""
    )

    with smtplib.SMTP(
        smtp_host,
        smtp_port,
    ) as server:
        server.starttls()

        server.login(
            smtp_user,
            smtp_password,
        )

        server.send_message(
            message
        )