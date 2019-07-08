CfhighlanderTemplate do
  Name 's3-cloudfront'
  Description "s3-cloudfront - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', isGlobal: true
  end

  Component name: cloudfront_component_name, template: 'cloudfront@0.4.0', render: Inline do
    parameter name: "s3bucketOriginDomainName", value: FnGetAtt('Bucket', 'DomainName')
  end

end
