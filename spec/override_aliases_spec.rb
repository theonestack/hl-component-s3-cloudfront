require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/override_aliases.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/override_aliases/s3-cloudfront.compiled.yaml") }
  
  context "Resource" do

    context "Distribution" do
        let(:resource) { template["Resources"]["Distribution"] }
        let(:distribution_config) { resource["Properties"]["DistributionConfig"] }
  
        it "is of type AWS::CloudFront::Distribution" do
            expect(resource["Type"]).to eq("AWS::CloudFront::Distribution")
        end
        
        it "to have property Aliases" do
            expect(distribution_config["Aliases"]).to eq({
                "Fn::If" => ["OverrideAliases", {"Fn::Split"=>[",", {"Ref"=>"cloudfrontOverrideAliases"}]}, [{"Fn::Sub"=>"www.example.com"}]]
            })
        end
        
      end
  end
  
end