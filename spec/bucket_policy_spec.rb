require 'yaml'

describe 'compiled component' do

  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/bucket_policy.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/bucket_policy/s3-cloudfront.compiled.yaml") }

  context "Resource" do

    context "Bucket" do
      let(:resource) { template["Resources"]["Bucket"] }

      it "to have property BucketName resolved through Fn::Sub" do
        expect(resource["Properties"]["BucketName"]).to eq({
          "Fn::Sub" => "frontend.${EnvironmentName}.${DnsDomain}"
        })
      end
    end

    context "BucketPolicy" do
      let(:resource) { template["Resources"]["BucketPolicy"] }
      let(:statements) { resource["Properties"]["PolicyDocument"]["Statement"] }

      it "is of type AWS::S3::BucketPolicy" do
        expect(resource["Type"]).to eq("AWS::S3::BucketPolicy")
      end

      it "keeps the default CloudFront grant alongside the configured statement" do
        expect(statements.length).to eq(2)
      end

      it "grants CloudFront read access to the bucket" do
        expect(statements[0]["Effect"]).to eq("Allow")
        expect(statements[0]["Principal"]).to eq({ "Service" => "cloudfront.amazonaws.com" })
        expect(statements[0]["Action"]).to eq("s3:GetObject")
      end

      it "appends the statement from the bucket_policy config" do
        expect(statements[1]["Sid"]).to eq("loadbalancer-logs")
        expect(statements[1]["Effect"]).to eq("Allow")
        expect(statements[1]["Action"]).to eq(["s3:PutObject"])
        expect(statements[1]["Principal"]).to eq({ "AWS" => "arn:aws:iam::111111111111:root" })
      end
    end

  end
end
