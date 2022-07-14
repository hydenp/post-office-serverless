from gmail import GmailService


def handler(event, context):
    # send the emails using the gmail service
    gmail_service = GmailService(token=event['auth']['token'], emails=event['emails'])
    return gmail_service.send_emails()
