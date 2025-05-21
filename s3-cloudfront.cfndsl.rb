CloudFormation do

  enable_s3_logging = external_parameters[:enable_s3_logging]
  origins = external_parameters.fetch(:origins, {})

  Condition(:SetLogFilePrefix, FnNot(FnEquals(Ref(:LogFilePrefix), ''))) if enable_s3_logging

  
  # A special loop ONLY for defining a single instance of a role/lambda/resource and using them as shared resources in S3 sources.
  if origins.filter{|k, v| (v['source'] == 's3') && (v['type'] == 'create_if_not_exists')}.length() > 0
    puts "looking S3 bucket type in #{component_name}"

    IAM_Role("BucketLambdaRole") {
      AssumeRolePolicyDocument({
        Version: '2012-10-17',
        Statement: [
          {
            Effect: 'Allow',
            Principal: {
              Service: [
                'lambda.amazonaws.com'
              ]
            },
            Action: 'sts:AssumeRole'
          }
        ]
      })
      Path '/'
      Policies([
        {
          PolicyName: FnSub("${EnvironmentName}-#{component_name}-create-s3-if-no-exists"),
          PolicyDocument: {
            Version: '2012-10-17',
            Statement: [
              {
                Effect: 'Allow',
                Action: [
                  'logs:CreateLogGroup',
                  'logs:CreateLogStream',
                  'logs:PutLogEvents'
                ],
                Resource: '*'
              },
              {
                Effect: 'Allow',
                Action: [
                  's3:CreateBucket',
                  's3:DeleteBucket',
                  's3:PutBucketNotification',
                  's3:GetBucketLocation',
                  's3:PutBucketCors',
                  's3:GetBucketCors',
                  's3:ListBucket'
                ],
                Resource: '*'
              }
            ]
          }
        }
      ])
    }

    code = external_parameters.fetch(:code, {})

    Lambda_Function("BucketLambda") {
      DependsOn ["BucketLambdaRole"]
      Code({
        ZipFile: code
      })
      Handler "index.handler"
      Runtime 'python3.11'
      Timeout 70
      Role FnGetAtt("BucketLambdaRole", :Arn)
    }

  end

  filtered = origins.filter {|k, v| v['source'] == 's3'}
  origins.each do |id,config|
  
    case config['source']
    when 's3'
      name_part = "-#{id}"
      saved_id = id
      if (filtered.map.with_index{|(k,v),i| k.to_s == id ? i.to_i : nil}.compact == [0])
        id = ""
        name_part = ""
      end
      bucket_encryption = config.has_key?('bucket_encryption') ? config['bucket_encryption'] : nil
      bucket_name = config.has_key?('bucket_name') ? config['bucket_name'] : FnJoin('', ['static', name_part, '-', Ref('EnvironmentName'), '-', Ref('AWS::Region'), '.', Ref('DnsDomain')])
      bucket_type = config.has_key?('type') ? config['type'] : 'default'

      block_public_access_default = {
        BlockPublicAcls: 'false',
        BlockPublicPolicy: 'false',
        IgnorePublicAcls: 'false',
        RestrictPublicBuckets: 'false'
      }
      block_pub_access = config.has_key?('block_pub_access') ? config['block_pub_access'] : block_public_access_default

      if bucket_type == 'create_if_not_exists'
        Resource("#{id}Bucket") do
          DependsOn ["BucketLambda"]
          Type 'Custom::S3BucketCreateOnly'
          Property 'ServiceToken', FnGetAtt("BucketLambda",'Arn')
          Property 'Region', Ref('AWS::Region')
          Property 'BucketName', bucket_name
        end
      else
        S3_Bucket("#{id}Bucket") do
          DeletionPolicy config['bucket_deletion_policy'] if config.has_key?('bucket_deletion_policy')
          BucketName bucket_name
          PublicAccessBlockConfiguration block_pub_access unless block_pub_access.nil?
          LoggingConfiguration ({
            DestinationBucketName: Ref(:AccessLogsBucket),
            LogFilePrefix: FnIf(:SetLogFilePrefix, Ref(:LogFilePrefix), Ref('AWS::NoValue'))
          }) if enable_s3_logging
          BucketEncryption bucket_encryption unless bucket_encryption.nil?
        end
      end

      use_access_identity = external_parameters.fetch(:use_access_identity, false)
      policy_document = {
        Version: '2008-10-17',
        Id: 'PolicyForCloudFrontContent'
      }

      if (use_access_identity == true)
        statement = {}
        statement['Effect'] = 'Allow'
        statement['Principal'] = { Service: 'cloudfront.amazonaws.com'}
        statement['Resource'] = FnJoin('', [ 'arn:aws:s3:::', bucket_name, '/*'])
        statement['Action'] = 's3:GetObject'
        statement['Principal'] = { CanonicalUser: { "Fn::GetAtt" => ["#{saved_id}OriginAccessIdentity", "S3CanonicalUserId"] }}
        policy_document["Statement"] = []
        policy_document["Statement"] << statement
      else
        statement = {}
        statement['Effect'] = 'Allow'
        statement['Principal'] = { Service: 'cloudfront.amazonaws.com'}
        statement['Resource'] = FnJoin('', [ 'arn:aws:s3:::', bucket_name, '/*'])
        statement['Action'] = 's3:GetObject'
        statement['Condition'] = { StringEquals: {'AWS:SourceArn': FnJoin('', ['arn:aws:cloudfront::', Ref('AWS::AccountId'), ':distribution/', 'Ref' => 'Distribution' ]) }}
        policy_document["Statement"] = []
        policy_document["Statement"] << statement
      end

      if (config.has_key?('bucket_policy') and !config['bucket_policy'].nil?)
        bucket_policy = config['bucket_policy']
        bucket_policy.each do |sid, statement_config|
          statement = {}
          statement["Sid"] = sid
          statement['Effect'] = statement_config.has_key?('effect') ? statement_config['effect'] : "Allow"
          statement['Principal'] = statement_config.has_key?('principal') ? statement_config['principal'] : {AWS: FnSub("arn:aws:iam::${AWS::AccountId}:root")}
          statement['Resource'] = statement_config.has_key?('resource') ? statement_config['resource'] : [FnJoin("",["arn:aws:s3:::", Ref("#{id}Bucket")]), FnJoin("",["arn:aws:s3:::", Ref("#{id}Bucket"), "/*"])]
          statement['Action'] = statement_config.has_key?('actions') ? statement_config['actions'] : ["s3:*"]
          statement['Condition'] = statement_config['conditions'] if statement_config.has_key?('conditions')
          policy_document[:Statement] << statement
        end
      end

      S3_BucketPolicy("#{id}BucketPolicy") do
        Bucket Ref("#{id}Bucket")
        PolicyDocument policy_document
      end

    end

  end if (defined? origins) && (origins.any?)

end