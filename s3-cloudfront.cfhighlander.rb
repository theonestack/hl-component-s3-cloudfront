CfhighlanderTemplate do
  Name 's3-cloudfront'
  Description "s3-cloudfront - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', isGlobal: true
  end

  Component name: 'cloudfront', template: 'cloudfront@master.snapshot', render: Inline


end
