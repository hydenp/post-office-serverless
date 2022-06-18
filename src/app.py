from googleapiclient.discovery import build

from auth import auth
from message import create_message


def handler(event, context):

    # get the authentication credentials
    creds = auth()

    # create the service with the creds
    service = build('gmail', 'v1', credentials=creds)

    # create the message with the
    mess = create_message(
        recipient=event["recipient"], subject=event["subject"], body=event["message"])

    result = service.users().messages().send(
        userId='me', body={'raw': mess}).execute()

    response = {
        "statusCode": 200,
        "body": result
    }

    return response


if __name__ == '__main__':
    test_request_body = {
        "recipient": "hyden.testing@gmail.com",
        "subject": "Test from Lambda",
        "message": "Test message"
    }

    handler(test_request_body, None)
