# Setlist Sherlock - Apple Music Token Server

This AWS Lambda function issues a ["Developer Token"](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens) (basically a JWT) signed with an Apple MusicKit private key, set to expire 6 months from the request time. These developer tokens are needed to allow Android Apple Music users (they do exist!) to authenticate. By using a Lambda function instead of storing the developer private key locally, you don't risk someone extracting your key from the compiled app. This is a good developer practice.

## Develop

Node 20+ is recommended. Install dependencies with:

```
$ yarn
```

### Environment Variables

Copy the `.env.example` to `.env` and fill in the values.

The `APPLE_TEAM_ID` is the Team ID under ["membership details" section](https://developer.apple.com/account).

To get your `MUSICKIT_PRIVATE_KEY`, head to [Certificates, Identifiers & Profiles -> Keys](https://developer.apple.com/account/resources/authkeys/list), then create a "Media Services" key. You'll need to click "configure" and add a media ID that you can create by going to [Identifiers](https://developer.apple.com/account/resources/identifiers/list) and selecting "Media IDs". Click "download" for the key to get the p8 key file, and open it in a text editor, removing the new lines.

After completing this step, you can also obtain your `MUSICKIT_PRIVATE_KEY_ID`. Click on the key you created and use the "Key ID".

## Test

Deploy the function locally using `yarn test`, this requires Docker to be set up.


## Deploy

To deploy this Lambda function, you need to install the [AWS CLI](https://aws.amazon.com/cli/). Run the below script, replacing `<aws-account-id>` with your AWS's numeric ID. Optionally provide a `<region-code>`, otherwise `us-east-1` is used.

This command will build the Docker image used for testing and deploy it to a [ECR](https://aws.amazon.com/ecr/) repository, and create the Lambda function if it doesn't exist already.

> This script may not work on Powershell on Windows. Use a Windows Subsystem for Linux installation.

```
$ yarn deploy <aws-account-id> <region-code>
```

If you'd prefer to deploy with CloudFormation, you can use the [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/using-sam-cli-deploy.html).

## Known issues

* The command that updates the Lambda's environment variables sometimes fails with a "ResourceConflictException". Run it manually if you need to add/update environment variables: `aws lambda update-function-configuration --region <your-aws-region> --function-name <your-DEPLOY_LAMBDA_NAME-value> --environment "Variables={EnvVar1=Value1,EnvVar2=Value2}"`
* The first time you create the function, the command fails with a "InvalidParameterValueException". The Lambda execution role does in fact work, just run the deploy again.
* If you're using the "function URL" feature, it's not set up properly by the script (because AWS's CLI is crappy) - you'll need to go into the Lambda function in the console, to the "configuration" tab then "function URL" in the side navigation, click Edit then Save. It'll add a policy that allows public access. Alternatively you can set up IAM authentication for your endpoint.
