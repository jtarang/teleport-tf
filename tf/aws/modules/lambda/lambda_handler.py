import json

def lambda_handler(event, context):
    """
    This is a basic boilerplate Lambda function handler in Python.
    This function is triggered when the Lambda is invoked.
    """
    # Log event and context for debugging
    print("Received event: " + json.dumps(event, indent=2))
    
    # Example: Return a basic response (you can customize this)
    response = {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Hello from Lambda!",
            "input": event
        })
    }
    
    # Return the response to the caller
    return response
