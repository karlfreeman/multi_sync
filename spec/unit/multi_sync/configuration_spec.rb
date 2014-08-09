require 'spec_helper'

describe MultiSync::Configuration do
  let(:configuration) { MultiSync::Configuration.new }
  context :configuration do
    describe :target_pool_size do
      it 'should default to celluloid_cores' do
        expect(configuration.target_pool_size).to eq Celluloid.cores
      end
      it 'should be settable' do
        configuration.target_pool_size = 3
        expect(configuration.target_pool_size).to be 3
      end
    end
    describe :credentials do
      it 'should be settable' do
        configuration.credentials = { foo: 'bar' }
        expect(configuration.credentials).to eq foo: 'bar'
      end
      context 'fog environment variables' do
        before do
          FileUtils.mkdir_p('/tmp/fog')
          File.open('/tmp/fog/.fog', 'w') do |f|
            f << "default:\n"
            f << "  aws_access_key_id: AWS_ACCESS_KEY_ID_DEFAULT\n"
            f << "  aws_secret_access_key: AWS_SECRET_ACCESS_KEY_DEFAULT\n"
            f << "alt:\n"
            f << "  aws_access_key_id: AWS_ACCESS_KEY_ID_ALT\n"
            f << '  aws_secret_access_key: AWS_SECRET_ACCESS_KEY_ALT'
          end
          Fog.instance_variable_set('@credential_path', nil)
          Fog.instance_variable_set('@credentials', nil)
          Fog.instance_variable_set('@credential', nil)
        end
        after do
          ENV['FOG_RC'] = nil
          ENV['FOG_CREDENTIAL'] = 'default'
          Fog.instance_variable_set('@credential_path', nil)
          Fog.instance_variable_set('@credentials', nil)
          Fog.instance_variable_set('@credential', nil)
        end
        it 'should default to fog credentials' do
          ENV['FOG_RC'] = nil
          ENV['FOG_CREDENTIAL'] = 'default'
          expect(configuration.credentials).to eq Fog.credentials
        end
        it 'should use fog credentials' do
          ENV['FOG_RC'] = '/tmp/fog/.fog'
          ENV['FOG_CREDENTIAL'] = 'default'
          expect(configuration.credentials).to eq(aws_access_key_id: 'AWS_ACCESS_KEY_ID_DEFAULT', aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY_DEFAULT')
        end
        it 'should use fog \'alt\' credentials' do
          ENV['FOG_RC'] = '/tmp/fog/.fog'
          ENV['FOG_CREDENTIAL'] = 'alt'
          expect(configuration.credentials).to eq(aws_access_key_id: 'AWS_ACCESS_KEY_ID_ALT', aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY_ALT')
        end
      end
    end
  end
end
