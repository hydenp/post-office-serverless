import base64
import json
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

import boto3
import google.auth.exceptions
from botocore.exceptions import ClientError
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

GOOGLE_SECRETS_NAMES = 'google/mailthem-test/postoffice-1'
SCOPES = ['https://mail.google.com/']


class GmailService:
    """
    retrieve auth from AWS Secrets Manager
    Create a Credentials object to use when building gmail service
    """

    def __init__(self, token, emails):
        self.token = token
        self.emails = emails

        self.service = self.get_gmail_service()

    @staticmethod
    def get_google_secret():
        """
        Retrieve the secrets from AWS Secrets Manager and return them in a dictionary

        :return: dict
        """
        secret_name = GOOGLE_SECRETS_NAMES
        region_name = "us-west-1"

        # Create a Secrets Manager client
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )

        # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
        # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
        # We rethrow the exception by default.

        try:
            get_secret_value_response = client.get_secret_value(
                SecretId=secret_name
            )
        except ClientError as e:
            if e.response['Error']['Code'] == 'DecryptionFailureException':
                # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InternalServiceErrorException':
                # An error occurred on the server side.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InvalidParameterException':
                # You provided an invalid value for a parameter.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'InvalidRequestException':
                # You provided a parameter value that is not valid for the current state of the resource.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
            elif e.response['Error']['Code'] == 'ResourceNotFoundException':
                # We can't find the resource that you asked for.
                # Deal with the exception here, and/or rethrow at your discretion.
                raise e
        else:
            # Decrypts secret using the associated KMS key.
            # Depending on whether the secret is a string or binary, one of these fields will be populated.
            if 'SecretString' in get_secret_value_response:
                secret = get_secret_value_response['SecretString']
                return json.loads(secret)
            else:
                decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
                return json.loads(decoded_binary_secret)

    def create_credentials(self):
        """
        create a credentials object with the token for building the service
        :return: google.oauth2.credentials.Credentials
        """
        # get the secrets from Amazon Secret Manager
        secrets = GmailService.get_google_secret()

        # create the credentials object
        return Credentials(
            token=self.token,
            client_id=secrets['google_client_id'],
            client_secret=secrets['google_client_secret'],
            scopes=SCOPES,
        )

    def get_gmail_service(self):
        """
        create a gmail service with the auth
        :return: googleapiclient.discovery.build
        """
        creds = self.create_credentials()
        return build('gmail', 'v1', credentials=creds)

    @staticmethod
    def bad_token():
        """
        return a response body with 207 to signify that service is unusable as token is bad
        :return: dict
        """
        return {
            "statusCode": 207,
            "headers": {
                "content-type": "application/json"
            },
            "body": "bad token"
        }

    def send_emails(self):
        """
        loop across the emails and try to send using created service
        :return: dict
        """
        results = []
        for email in self.emails:
            # create the message
            message = MimeMessage(recipient=email["recipient"], subject=email["subject"], body=email["body"])

            # try and send the message. catch the exception if the token is no good
            try:
                result = message.send(self.service)
            except google.auth.exceptions.RefreshError:
                return GmailService.bad_token()

            results.append({
                "recipient": email["recipient"],
                "status": result["labelIds"][0]
            })

        return {
            "statusCode": 200,
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps({"results": results})
        }


class MimeMessage:

    def __init__(self, recipient, subject, body):
        """
        create the message as a mime message upon instantiation
        :param recipient: string
        :param subject: string
        :param body: string
        """
        self.mime_message = MimeMessage.create_message_without_attachment(recipient, subject, body)

    @staticmethod
    def create_message_without_attachment(recipient, subject, body):
        """
        create a mime multipart message to send that does not contain any attachments
        :param recipient: string
        :param subject: string
        :param body: string
        :return: MIMEMultipart message object to
        """
        mime_message = MIMEMultipart()
        mime_message['to'] = recipient
        mime_message['subject'] = subject
        mime_message.attach(MIMEText(body, 'plain'))
        return base64.urlsafe_b64encode(mime_message.as_bytes()).decode()

    def send(self, service):
        """
        send the email using the provided service
        :param service: googleapiclient.discovery.build
        :return: dict - result of the call to the gmail api
        """
        return service.users().messages().send(
            userId='me', body={'raw': self.mime_message}).execute()
