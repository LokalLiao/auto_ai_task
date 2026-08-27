import json
from pathlib import Path
from email.message import EmailMessage
import mimetypes
import smtplib

# 发送邮件到指定邮箱
class EmailSender:

    def __init__(self):
        self.config = self._load_config()

    def _load_config(self):
        config_path = Path(__file__).resolve().parent / "config.json"
        if not config_path.exists():
            raise FileNotFoundError(f"Config file not found: {config_path}")
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)

    # 发送邮件，可选附件发送
    def send(self, to_email: str, subject: str, body: str, attachment: str | Path | None = None):
        message = EmailMessage()
        message["From"] = self.config["email"]
        message["To"] = to_email
        message["Subject"] = subject
        message.set_content(body)
        if attachment:
            attachment_path = Path(attachment)
            if not attachment_path.exists():
                raise FileNotFoundError(f"附件不存在: {attachment_path}")
            mime_type, _ = mimetypes.guess_type(attachment_path.name)
            if mime_type:
                maintype, subtype = mime_type.split("/", 1)
            else:
                maintype = "application"
                subtype = "octet-stream"
            with open(attachment_path, "rb") as f:
                message.add_attachment(
                    f.read(),
                    maintype=maintype,
                    subtype=subtype,
                    filename=attachment_path.name
                )
            with smtplib.SMTP_SSL(
                    self.config["smtp_server"],
                    self.config["smtp_port"]) as smtp:
                smtp.login(self.config["email"], self.config["email_password"])
                smtp.send_message(message)
        print(f"邮件发送成功: {to_email}")