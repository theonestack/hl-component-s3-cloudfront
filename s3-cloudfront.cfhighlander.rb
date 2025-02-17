CfhighlanderTemplate do
  Name 's3-cloudfront'
  Description "s3-cloudfront - #{component_version}"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', isGlobal: true
    if enable_s3_logging
      ComponentParam 'LogFilePrefix', ''
      ComponentParam 'AccessLogsBucket'
    end
  end

  Component name: cloudfront_component_name, template: 'cloudfront@0.8.3', render: Inline, config: @config do
    additional_parameters.each do |parameter_name|
      parameter name: parameter_name, value: Ref(parameter_name)
    end if defined? additional_parameters
  end

end
