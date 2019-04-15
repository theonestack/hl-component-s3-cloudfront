CloudFormation do

  policy_document = {
    Version: '2008-10-17',
    Id: 'PolicyForCloudFrontContent',
    Statement: [
      {
        Effect: 'Allow',
        Action: 's3:GetObject',
        Resource: FnJoin('', [ 'arn:aws:s3:::', Ref("Bucket"), '/*']),
        Principal: { CanonicalUser: FnGetAtt('s3bucketOriginAccessIdentity', 'S3CanonicalUserId') }
      }
    ]
  }

if defined? bucket_policy

  bucket_policy.each do |sid, statement_config|
    statement = {}
    statement["Sid"] = sid
    statement['Effect'] = statement_config.has_key?('effect') ? statement_config['effect'] : "Allow"
    statement['Principal'] = statement_config.has_key?('principal') ? statement_config['principal'] : {AWS: FnSub("arn:aws:iam::${AWS::AccountId}:root")}
    statement['Resource'] = statement_config.has_key?('resource') ? statement_config['resource'] : [FnJoin("",["arn:aws:s3:::", Ref('Bucket')]), FnJoin("",["arn:aws:s3:::", Ref('Bucket'), "/*"])]
    statement['Action'] = statement_config.has_key?('actions') ? statement_config['actions'] : ["s3:*"]
    statement['Condition'] = statement_config['conditions'] if statement_config.has_key?('conditions')
    policy_document[:Statement] << statement
  end

end


  S3_Bucket('Bucket') do
    BucketName FnSub(bucket_name)
  end

  S3_BucketPolicy("BucketPolicy") do
    Bucket Ref('Bucket')
    PolicyDocument policy_document
  end
end