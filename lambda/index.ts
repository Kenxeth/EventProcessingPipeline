import type { APIGatewayProxyHandlerV2, SQSEvent, APIGatewayProxyEventV2 } from 'aws-lambda'
import {SQSClient, SendMessageCommand} from "@aws-sdk/client-sqs";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3"
import {
  DynamoDBDocumentClient,
  PutCommand,
  GetCommand,
} from "@aws-sdk/lib-dynamodb";

const sqs = new SQSClient();
const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const s3 = new S3Client({});

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
    console.log('Received SQS message:', messageBody);

    // Store the event in S3
    await s3.send(new PutObjectCommand({
      Bucket: process.env.S3_BUCKET_NAME,
      Key: `events/${messageBody.user_id}/${messageBody.event_id}.json`,
      Body: JSON.stringify(messageBody),
      ContentType: "application/json"
    }));

    // Store the event in DynamoDB
    const checkIfItemExists = await dynamo.send(new GetCommand({
      TableName: process.env.DYNAMODB_TABLE_ARN,
      Key: {
        user_id: messageBody.user_id,
        event_id: messageBody.event_id
      }
    }));

    if (checkIfItemExists.Item) {
      console.log(`Event with event_id ${messageBody.event_id} already exists in DynamoDB. Skipping insertion.`);
      continue; // Skip to the next record
    }


    await dynamo.send(
      new PutCommand({
        TableName: process.env.DYNAMODB_TABLE_ARN,
        Item: messageBody
      })
    );

  }

}