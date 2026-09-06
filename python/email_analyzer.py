import email
import imaplib
import json
from datetime import datetime
from email.header import decode_header
from pathlib import Path
from typing import List, Optional
from bs4 import BeautifulSoup
from google import genai
from google.genai import types
from pydantic import BaseModel

class EmailSummaryItem(BaseModel):
    id: str  # 记录邮件 UID
    sender: str
    subject: str
    received_time: str
    is_spam_or_ad: bool
    category: str
    summary: str
    key_points: List[str]
    action_items: List[str]
    risk_warning: str

class EmailAnalyzer:

    def __init__(self):
        self.base_dir = Path(__file__).resolve().parent
        self.prompt_dir = self.base_dir / "prompts"
        self.config = self._load_config()
        self.ai_client = genai.Client(api_key=self.config["gemini_api_key"])

    def _load_config(self) -> dict:
        config_path = self.base_dir / "config.json"
        if not config_path.exists():
            raise FileNotFoundError(f"Config file not found: {config_path}")
        with open(config_path, "r", encoding="utf-8") as f:
            return json.load(f)

    def _load_prompt_template(self, prompt_name: str) -> str:
        """从 prompts 目录加载指定文本模板"""
        prompt_file = self.prompt_dir / f"{prompt_name}.txt"
        if not prompt_file.exists():
            raise FileNotFoundError(f"Prompt template not found: {prompt_file}")
        with open(prompt_file, "r", encoding="utf-8") as f:
            return f.read()

    def analyze_today_emails(self) -> List[EmailSummaryItem]:
        """抓取当天所有邮件并使用 Gemini 进行结构化分析"""
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login(self.config["email"], self.config["email_password"])
        mail.select("INBOX")
        today_imap_date = datetime.now().strftime("%d-%b-%Y")
        # 采用 UID 检索，避免删除邮件时序列号错位
        status, messages = mail.uid("SEARCH", None, f'(SINCE "{today_imap_date}")')
        if status != "OK":
            mail.logout()
            raise Exception("搜索当天邮件失败")
        mail_uids = messages[0].split()
        results: List[EmailSummaryItem] = []
        # 倒序遍历（优先分析最新收到的邮件）
        for m_uid in reversed(mail_uids):
            res, data = mail.uid("FETCH", m_uid, "(RFC822)")
            if res != "OK" or not data or not data[0]:
                continue
            raw_email = data[0][1]
            msg = email.message_from_bytes(raw_email)
            subject = self._decode_header_str(msg.get("Subject", "无主题"))
            sender = self._decode_header_str(msg.get("From", "未知发件人"))
            date_str = msg.get("Date", "")
            body = self._extract_body(msg)
            analysis = self._call_gemini_analysis(sender, subject, body)
            results.append(
                EmailSummaryItem(
                    id=m_uid.decode("utf-8"),
                    sender=sender,
                    subject=subject,
                    received_time=date_str,
                    is_spam_or_ad=analysis.get("is_spam_or_ad", False),
                    category=analysis.get("category", "其他"),
                    summary=analysis.get("summary", ""),
                    key_points=analysis.get("key_points", []),
                    action_items=analysis.get("action_items", []),
                    risk_warning=analysis.get("risk_warning", "无"),
                )
            )
        mail.close()
        mail.logout()
        return results

    def _call_gemini_analysis(self, sender: str, subject: str, content: str) -> dict:
        """读取外部提示词模板并调用 Gemini"""
        template = self._load_prompt_template("email_analysis")
        prompt = template.format(sender=sender, subject=subject, content=content)
        try:
            response = self.ai_client.models.generate_content(
                model="gemini-3.6-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    response_mime_type="application/json",
                ),
            )
            return json.loads(response.text)
        except Exception as e:
            print(f"[Gemini 错误]: {e}")
            return {
                "is_spam_or_ad": False,
                "category": "解析异常",
                "summary": "AI 解析失败",
                "key_points": [],
                "action_items": [],
                "risk_warning": "无",
            }

    def delete_email(self, mail_uid: str, folder: str = "INBOX") -> bool:
        """根据 UID 删除单封邮件"""
        return self.delete_emails([mail_uid], folder=folder)

    def delete_emails(self, mail_uids: List[str], folder: str = "INBOX") -> bool:
        """根据 UID 列表批量删除邮件"""
        if not mail_uids:
            return True
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        try:
            mail.login(self.config["email"], self.config["email_password"])
            mail.select(folder)
            uid_set = ",".join(mail_uids)
            # 1. 标记删除
            status, _ = mail.uid("STORE", uid_set, "+FLAGS", "(\\Deleted)")
            if status != "OK":
                return False
            # 2. 执行清除
            mail.expunge()
            return True
        except Exception as e:
            print(f"[IMAP 删除失败]: {e}")
            return False
        finally:
            try:
                mail.close()
                mail.logout()
            except Exception:
                pass

    def _extract_body(self, msg: email.message.Message) -> str:
        """提取纯文本正文并清理 HTML 标签"""
        body = ""
        if msg.is_multipart():
            for part in msg.walk():
                content_type = part.get_content_type()
                content_disposition = str(part.get("Content-Disposition"))
                if "attachment" not in content_disposition:
                    if content_type == "text/plain":
                        payload = part.get_payload(decode=True)
                        if payload:
                            body += payload.decode(errors="ignore")
                    elif content_type == "text/html" and not body:
                        payload = part.get_payload(decode=True)
                        if payload:
                            html = payload.decode(errors="ignore")
                            body += BeautifulSoup(html, "html.parser").get_text()
        else:
            content_type = msg.get_content_type()
            payload = msg.get_payload(decode=True)
            if payload:
                if content_type == "text/plain":
                    body = payload.decode(errors="ignore")
                elif content_type == "text/html":
                    html = payload.decode(errors="ignore")
                    body = BeautifulSoup(html, "html.parser").get_text()
        return body.strip()[:3500]

    def _decode_header_str(self, header_value: str) -> str:
        """解码 MIME 邮件头"""
        if not header_value:
            return ""
        decoded_fragments = decode_header(header_value)
        result = []
        for content, charset in decoded_fragments:
            if isinstance(content, bytes):
                result.append(content.decode(charset or "utf-8", errors="ignore"))
            else:
                result.append(str(content))
        return "".join(result)


if __name__ == "__main__":
    analyzer = EmailAnalyzer()
    items = analyzer.analyze_today_emails()
    spam_uids = []
    for item in items:
        print(item.model_dump_json(indent=2))
        if item.is_spam_or_ad:
            spam_uids.append(item.id)
    # 自动清理垃圾邮件示例
    # if spam_uids:
    #     print(f"正在清理垃圾邮件 (UIDs: {spam_uids})...")
    #     success = analyzer.delete_emails(spam_uids)
    #     print(f"清理状态: {'成功' if success else '失败'}")