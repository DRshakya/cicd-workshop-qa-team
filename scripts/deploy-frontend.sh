#!/bin/bash
set -e

echo "🚀 Starting Frontend Deployment to S3..."

# Get branch name
branch_name="${GITHUB_REF#refs/heads/}"
echo "📋 Deploying branch: $branch_name"

# Build frontend
echo "🔨 Building frontend application..."
cd frontend

# Install dependencies
npm ci

# Build with environment-specific variables
echo "🧪 Building for staging..."
REACT_APP_API_URL="$STAGING_API_URL" npm run build

fi

# Deploy to S3
echo "☁️ Deploying to S3 bucket..."
aws s3 sync ./build s3://"$S3_BUCKET_NAME" --delete --exact-timestamps

# Set cache control for different file types
echo "🔄 Setting cache policies..."
# Cache HTML files for short time (for updates)
aws s3 cp s3://"$S3_BUCKET_NAME"/index.html s3://"$S3_BUCKET_NAME"/index.html \
    --metadata-directive REPLACE \
    --cache-control "max-age=0, no-cache, no-store, must-revalidate"

# Cache static assets for longer
aws s3 cp s3://"$S3_BUCKET_NAME"/static s3://"$S3_BUCKET_NAME"/static \
    --recursive \
    --metadata-directive REPLACE \
    --cache-control "max-age=31536000, public, immutable" || true

# Invalidate CloudFront cache (if you have CloudFront)
if [ ! -z "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo "🔄 Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id "$CLOUDFRONT_DISTRIBUTION_ID" \
        --paths "/*"
fi
