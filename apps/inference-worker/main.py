import json
import logging
import os
import tempfile

import boto3
import torch
from botocore.exceptions import ClientError
from ultralytics import YOLO


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)

logger = logging.getLogger(__name__)


# --------------------------------------------------
# Environment variables
# --------------------------------------------------

SQS_QUEUE_URL = os.environ["SQS_QUEUE_URL"]

MODEL_BUCKET = os.environ["MODEL_BUCKET"]
MODEL_PATH = os.environ["MODEL_PATH"]

RESULTS_BUCKET = os.environ["RESULTS_BUCKET"]

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

LOCAL_MODEL_PATH = "/tmp/model.pt"


# --------------------------------------------------
# AWS clients
# --------------------------------------------------

s3 = boto3.client(
    "s3",
    region_name=AWS_REGION,
)

sqs = boto3.client(
    "sqs",
    region_name=AWS_REGION,
)


# --------------------------------------------------
# AWS access checks
# --------------------------------------------------

def check_s3_access():
    """
    Verify that the worker can:

    1. Read the model from S3.
    2. Write results to the results bucket.
    """

    logger.info("Checking S3 access...")

    try:
        # Check model read access.
        #
        # head_object verifies that the object exists and
        # that the IAM role has permission to access it.
        s3.head_object(
            Bucket=MODEL_BUCKET,
            Key=MODEL_PATH,
        )

        logger.info(
            "S3 model access OK: s3://%s/%s",
            MODEL_BUCKET,
            MODEL_PATH,
        )

        # Check results bucket access.
        #
        # We use get_bucket_location rather than writing a
        # test object, so startup doesn't create junk objects.
        s3.get_bucket_location(
            Bucket=RESULTS_BUCKET,
        )

        logger.info(
            "S3 results bucket access OK: %s",
            RESULTS_BUCKET,
        )

    except ClientError as exc:
        logger.error(
            "S3 access check failed: %s",
            exc,
        )
        raise RuntimeError(
            "GPU worker does not have the required S3 permissions."
        ) from exc


def check_sqs_access():
    """
    Verify that the worker can access the SQS queue.
    """

    logger.info("Checking SQS access...")

    try:
        # Verifies that the queue exists and that the IAM role
        # can access it.
        sqs.get_queue_attributes(
            QueueUrl=SQS_QUEUE_URL,
            AttributeNames=["QueueArn"],
        )

        logger.info(
            "SQS access OK: %s",
            SQS_QUEUE_URL,
        )

        # Actually verify ReceiveMessage permission.
        #
        # With long polling enabled, this will simply return
        # no messages if the queue is empty.
        sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=1,
        )

        logger.info("SQS ReceiveMessage permission OK")

    except ClientError as exc:
        logger.error(
            "SQS access check failed: %s",
            exc,
        )
        raise RuntimeError(
            "GPU worker does not have the required SQS permissions."
        ) from exc


# --------------------------------------------------
# CUDA / GPU verification
# --------------------------------------------------

def check_gpu():
    """
    Verify that CUDA and an NVIDIA GPU are available.
    """

    logger.info("Checking CUDA/GPU...")

    if not torch.cuda.is_available():
        raise RuntimeError(
            "CUDA is not available. GPU worker cannot start."
        )

    device = torch.device("cuda:0")

    logger.info(
        "CUDA available: %s",
        torch.cuda.is_available(),
    )

    logger.info(
        "CUDA version: %s",
        torch.version.cuda,
    )

    logger.info(
        "GPU: %s",
        torch.cuda.get_device_name(0),
    )

    return device


# --------------------------------------------------
# Model loading
# --------------------------------------------------

def load_model(device):
    """
    Download the model from S3 and load it onto the GPU.
    """

    logger.info(
        "Downloading model from s3://%s/%s",
        MODEL_BUCKET,
        MODEL_PATH,
    )

    try:
        s3.download_file(
            MODEL_BUCKET,
            MODEL_PATH,
            LOCAL_MODEL_PATH,
        )

    except ClientError as exc:
        logger.error(
            "Failed to download model from S3: %s",
            exc,
        )
        raise RuntimeError(
            "Could not download model from S3."
        ) from exc

    logger.info(
        "Model downloaded to %s",
        LOCAL_MODEL_PATH,
    )

    logger.info("Loading YOLO model onto GPU...")

    model = YOLO(LOCAL_MODEL_PATH)

    model.to(device)

    logger.info(
        "YOLO model loaded successfully on %s",
        device,
    )

    return model


# --------------------------------------------------
# Process SQS message
# --------------------------------------------------

def process_message(message, model):

    body = json.loads(message["Body"])

    input_bucket = body["bucket"]
    input_key = body["key"]

    logger.info(
        "Processing s3://%s/%s",
        input_bucket,
        input_key,
    )

    extension = os.path.splitext(input_key)[1]

    with tempfile.NamedTemporaryFile(
        suffix=extension,
        delete=False,
    ) as tmp:

        local_path = tmp.name

    try:

        # --------------------------------------------------
        # Download input image
        # --------------------------------------------------

        s3.download_file(
            input_bucket,
            input_key,
            local_path,
        )

        logger.info("Downloaded image")

        # --------------------------------------------------
        # GPU inference
        # --------------------------------------------------

        results = model.predict(
            source=local_path,
            device=0,
            verbose=False,
        )

        detections = []

        for result in results:

            for box in result.boxes:

                detections.append(
                    {
                        "class_id": int(box.cls[0]),
                        "confidence": float(box.conf[0]),
                        "bbox": [
                            float(x)
                            for x in box.xyxy[0].tolist()
                        ],
                    }
                )

        # --------------------------------------------------
        # Build result
        # --------------------------------------------------

        output = {
            "input": {
                "bucket": input_bucket,
                "key": input_key,
            },
            "detections": detections,
        }

        result_key = (
            os.path.splitext(input_key)[0]
            + ".json"
        )

        # --------------------------------------------------
        # Upload results
        # --------------------------------------------------

        s3.put_object(
            Bucket=RESULTS_BUCKET,
            Key=result_key,
            Body=json.dumps(output),
            ContentType="application/json",
        )

        logger.info(
            "Results uploaded to s3://%s/%s",
            RESULTS_BUCKET,
            result_key,
        )

    finally:

        if os.path.exists(local_path):
            os.remove(local_path)


# --------------------------------------------------
# Worker loop
# --------------------------------------------------

def worker_loop(model):

    logger.info("GPU worker started")

    while True:

        response = sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=1,
            WaitTimeSeconds=20,
            VisibilityTimeout=300,
        )

        messages = response.get("Messages", [])

        if not messages:
            continue

        for message in messages:

            try:

                process_message(
                    message,
                    model,
                )

                # Delete ONLY after successful processing.
                #
                # If inference or S3 upload fails, the message
                # remains in SQS and becomes visible again after
                # the visibility timeout.

                sqs.delete_message(
                    QueueUrl=SQS_QUEUE_URL,
                    ReceiptHandle=message["ReceiptHandle"],
                )

                logger.info("Message completed")

            except Exception:

                logger.exception(
                    "Processing failed. "
                    "Message will be retried."
                )


# --------------------------------------------------
# Application startup
# --------------------------------------------------

def main():

    logger.info("Starting GPU worker...")

    # 1. Check AWS access BEFORE loading model
    check_s3_access()
    check_sqs_access()

    # 2. Check GPU
    device = check_gpu()

    # 3. Download and load model
    model = load_model(device)

    # 4. Start worker
    worker_loop(model)


if __name__ == "__main__":
    main()