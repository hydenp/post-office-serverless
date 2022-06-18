import base64
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


def create_message(recipient, subject, body):

    emailMsg = body
    mimeMessage = MIMEMultipart()
    mimeMessage['to'] = recipient
    mimeMessage['subject'] = subject
    mimeMessage.attach(MIMEText(emailMsg, 'plain'))
    return base64.urlsafe_b64encode(mimeMessage.as_bytes()).decode()
