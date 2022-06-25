from gmail import GmailService, MimeMessage


def handler(event, context):
    # get the authentication credentials from the payload
    service = GmailService.get_gmail_service(token=event['auth']['token'])

    results = []
    for email in event['emails']:
        # create the message
        message = MimeMessage(recipient=email["recipient"], subject=email["subject"], body=email["body"])

        # send the message
        print('sending...')
        result = message.send(service)

        print(result)
        results.append(result)

    return {
        "statusCode": 200,
        "body": results
    }
