import type { APIGatewayProxyHandlerV2, SQSEvent, APIGatewayProxyEventV2 } from 'aws-lambda'
import {SQSClient, SendMessageCommand} from "@aws-sdk/client-sqs";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand
} from "@aws-sdk/lib-dynamodb";

const sqs = new SQSClient();
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);

function returnInvalidEventResponse() {
  return {
    statusCode: 400,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: "Invalid event data" })
  }
}

export const handler: APIGatewayProxyHandlerV2 = async (event : APIGatewayProxyEventV2) => {
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

export const SQSToLambdaHandler = async (event: SQSEvent) => {

  for (const record of event.Records) {
    const messageBody = JSON.parse(record.body);


    await dynamo.send(
      new PutCommand({
        TableName: process.env.DYNAMODB_TABLE_ARN,
        Item: messageBody
      })
    );

    console.log('Received SQS message:', messageBody);
  }

}