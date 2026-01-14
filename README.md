# Setlist Sherlock - Apple Music Token Server

This Scaleway Serverless Function issues a ["Developer Token"](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens) (basically a JWT) signed with an Apple MusicKit private key, set to expire 6 months from the request time. These developer tokens are needed to allow Android Apple Music users (they do exist!) to authenticate. By using a Serverless Function instead of storing the developer private key locally, you don't risk someone extracting your key from the compiled app. This is a good developer practice.

## Develop

Node 22+ is required. Install dependencies with:

```
yarn
```

### Environment Variables

Fill in the details in `infra/terraform.tfvars` using the `variables.tf` file as a guide.

## Deploy

This serverless function is deployed via [OpenTofu](https://opentofu.org/docs/intro/install/).
