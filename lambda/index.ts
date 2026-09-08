import type { APIGatewayProxyHandlerV2 } from 'aws-lambda'
import {SQSClient, SendMessageCommand} from "@aws-sdk/client-sqs";

const sqs = new SQSClient();

function returnInvalidEventResponse() {
  return {
    statusCode: 400,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: "Invalid event data" })
  }
}

export const handler: APIGatewayProxyHandlerV2 = async (event) => {
  // console.log('Received event:', JSON.stringify(event, null, 2))
  let rawBody = event.body;

  if(rawBody === undefined) {
    return returnInvalidEventResponse();
  }

  if (event.isBase64Encoded) {
    rawBody = Buffer.from(rawBody, "base64").toString("utf-8");
  }

  const body = JSON.parse(rawBody)

  // console.log('Parsed body after base64 decoding:', JSON.stringify(body))

  if(!body.event_id || !body.event_type || !body.user_id || !body.amount) {
    return returnInvalidEventResponse();
  }

  // Sending the valid event to SQS queue
  const command = new SendMessageCommand({
    QueueUrl: process.env.QUEUE_URL,
    MessageBody: JSON.stringify(body)
  });

  await sqs.send(command);

  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: "Event is valid" })
  }

}