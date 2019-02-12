CloudFormation do

  policy_document = {
    Version: '2008-10-17',
    Id: 'PolicyForCloudFrontContent',
    Statement: [
      {
        Effect: 'Allow',
        Action: 's3:GetObject',
        Resource: FnJoin('', [ 'arn:aws:s3:::', Ref("Bucket"), '/*']),
        Principal: { CanonicalUser: FnGetAtt(:Distribution, 'S3CanonicalUserId') }
      }
    ]
  }
  
  
  S3_Bucket('Bucket') do 
    BucketName FnSub(bucket_name)
  end

  S3_BucketPolicy("BucketPolicy") do 
    Bucket Ref('Bucket')
    PolicyDocument policy_document
  end
end