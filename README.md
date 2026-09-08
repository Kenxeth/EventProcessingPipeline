<h1> Serverless Event Processing Pipeline </h1>

EventFlow is an event-driven backend built with AWS and Terraform. It accepts events through an HTTP endpoint, buffers them in Amazon SQS, and processes them asynchronously with AWS Lambda. Processed events are stored in DynamoDB, while JSON payloads are archived in Amazon S3.

The project explores asynchronous processing, queue-based retries, failure isolation, and infrastructure as code without requiring a frontend or an always-running application server.


<img width="1350" height="889" alt="EventFlow Serverless Event Processing Architecture" src="https://github.com/user-attachments/assets/628b4de5-fb81-47bd-b083-4d0e8bdb4057" />



<hr>


<h1> How an Event Moves Through the System </h1>

1) A client submits a JSON event to POST /events.

2) API Gateway invokes the ingestion Lambda with the HTTP request.

3) The ingestion Lambda extracts the event and sends it to SQS. Successful ingestion means the event has been queued; downstream processing happens separately.

4) Lambda's SQS event source mapping polls the queue and invokes the worker with a batch of messages.

5) The worker parses each message body and writes the event to DynamoDB and S3.

6) After successful processing, Lambda's event source mapping deletes the successfully processed messages from the queue.

7) Failed messages become available for another attempt after the visibility timeout. Messages that exceed the queue's configured receive limit are moved to the dead-letter queue.
