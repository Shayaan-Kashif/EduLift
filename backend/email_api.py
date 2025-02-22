from flask import Flask, request, jsonify
from azure.communication.email import EmailClient
from dotenv import load_dotenv
import os

app = Flask(__name__)

load_dotenv()

CONNECTION_STRING = os.getenv("COMMUNICATION_SERVICES_CONNECTION_STRING")

# Initialize Email Client
email_client = EmailClient.from_connection_string(CONNECTION_STRING)

@app.route("/send-email", methods=["POST"])
def send_email():
    try:
        # Parse JSON data from request
        data = request.get_json()
        recipient = data.get("recipient")
        subject = data.get("subject", "No Subject")
        plain_text = data.get("plain_text", "")
        html_content = data.get("html_content", "")

        # Validate required fields
        if not recipient or not plain_text:
            return jsonify({"error": "Recipient email and plain text content are required"}), 400

        # Prepare email message
        message = {
            "senderAddress": "DoNotReply@c23a789b-1c51-4d75-abf5-be993d8c827b.azurecomm.net",
            "recipients": {
                "to": [{"address": recipient}]
            },
            "content": {
                "subject": subject,
                "plainText": plain_text,
                "html": html_content
            }
        }

        # Send email
        poller = email_client.begin_send(message)
        result = poller.result()

        return jsonify({"message": "Email sent successfully", "message_id": result.message_id})

    except Exception as ex:
        return jsonify({"error": str(ex)}), 500

# Run the Flask app
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000, debug=True)
