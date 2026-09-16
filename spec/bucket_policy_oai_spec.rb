require 'yaml'

describe 'compiled component' do

  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/bucket_policy_oai.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/bucket_policy_oai/s3-cloudfront.compiled.yaml") }

  context "Resource" do

    context "BucketPolicy" do
      let(:resource) { template["Resources"]["BucketPolicy"] }
      let(:statements) { resource["Properties"]["PolicyDocument"]["Statement"] }
      let(:canonical_user) {
        { "CanonicalUser" => { "Fn::GetAtt" => ["s3bucketOriginAccessIdentity", "S3CanonicalUserId"] } }
      }

      it "keeps the origin access identity grant alongside the configured statement" do
        expect(statements.length).to eq(2)
      end

      it "grants the origin access identity read access to the bucket" do
        expect(statements[0]["Effect"]).to eq("Allow")
        expect(statements[0]["Principal"]).to eq(canonical_user)
      end

      it "appends a Deny statement that can narrow the grant by prefix" do
        expect(statements[1]["Sid"]).to eq("deny-private-prefix")
        expect(statements[1]["Effect"]).to eq("Deny")
        expect(statements[1]["Principal"]).to eq(canonical_user)
        expect(statements[1]["Resource"]).to eq([
          { "Fn::Sub" => "arn:aws:s3:::${Bucket}/private/*" }
        ])
      end
    end

  end
end
