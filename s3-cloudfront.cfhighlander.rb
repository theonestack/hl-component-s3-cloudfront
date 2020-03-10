CfhighlanderTemplate do

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', isGlobal: true
  end

  Component name: cloudfront_component_name, template: 'cloudfront@apex_dns', render: Inline, config: @config do
    parameter name: "s3bucketOriginDomainName", value: FnGetAtt('Bucket', 'DomainName')
  end

end
