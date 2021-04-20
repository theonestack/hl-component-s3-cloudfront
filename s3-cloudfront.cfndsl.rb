CloudFormation do

  policy_document = {
    Version: '2008-10-17',
    Id: 'PolicyForCloudFrontContent',
    Statement: [
      {
        Effect: 'Allow',
        Action: 's3:GetObject',
        Resource: FnJoin('', [ 'arn:aws:s3:::', Ref("Bucket"), '/*']),
        Principal: { CanonicalUser: { "Fn::GetAtt" => ['s3bucketOriginAccessIdentity', 'S3CanonicalUserId'] }}
      }
    ]
  }


  bucket_policy = external_parameters.fetch(:bucket_policy, {})
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


  bucket_encryption = external_parameters.fetch(:bucket_encryption, nil)
  enable_s3_logging = external_parameters[:enable_s3_logging]
  block_pub_access = external_parameters.fetch(:block_pub_access, nil)

  Condition(:SetLogFilePrefix, FnNot(FnEquals(Ref(:LogFilePrefix), ''))) if enable_s3_logging

  S3_Bucket('Bucket') do
    BucketName FnSub(external_parameters[:bucket_name])
    PublicAccessBlockConfiguration block_pub_access unless block_pub_access.nil?
    LoggingConfiguration ({
      DestinationBucketName: Ref(:AccessLogsBucket),
      LogFilePrefix: FnIf(:SetLogFilePrefix, Ref(:LogFilePrefix), Ref('AWS::NoValue'))
    }) if enable_s3_logging
    BucketEncryption bucket_encryption unless bucket_encryption.nil?
  end

  S3_BucketPolicy("BucketPolicy") do
    Bucket Ref('Bucket')
    PolicyDocument policy_document
  end
end
