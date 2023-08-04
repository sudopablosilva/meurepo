import requests
import boto3
# a method that makes a GET request to the specified url
def get_request(url):
    response = requests.get(url)
    return response.json()

print(get_request('https://api.github.com/users/sudopablosilva'))

# a method that lists all the buckets in the AWS account
def list_buckets():
    s3 = boto3.resource('s3')
    return [bucket.name for bucket in s3.buckets.all()]

# Print the buckets
print(list_buckets())
