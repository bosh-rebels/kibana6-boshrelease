require 'rspec'
require 'yaml'
require 'bosh/template/test'
require 'base64'

describe 'kibana job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('kibana') }

  describe 'kibana.yml' do
    let(:template) { job.template('config/kibana.yml') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'configures defaults successfully' do
      config = YAML.safe_load(template.render({}, consumes: links))
      expect(config['server.port']).to eq(5601)
      expect(config['server.host']).to eq('0.0.0.0')
      expect(config['kibana.index']).to eq('.kibana')
      expect(config['kibana.defaultAppId']).to eq('discover')
      expect(config['elasticsearch.hosts']).to eq(['http://10.0.8.2:9200'])
      expect(config['elasticsearch.requestTimeout']).to eq(300000)
      expect(config['elasticsearch.shardTimeout']).to eq(30000)
    end

    it 'makes a request to ES secure' do
      config = YAML.safe_load(template.render({
        'kibana' => {
          'elasticsearch' => {
            'protocol' => 'https',
            'security' => {
              'enabled' => true,
              'username' => 'admin',
              'password' => 'password'
            },
          },
          'xpack' => {
            'encryptedSavedObjects' => {
              'encryptionKey' => 'something'
            }
          }
        }
      }, consumes: links))
      expect(config['elasticsearch.hosts']).to eq(['https://10.0.8.2:9200'])
      expect(config['elasticsearch.username']).to eq('admin')
      expect(config['elasticsearch.password']).to eq('password')
    end

    it 'configures kibana.config_options' do
      config = YAML.safe_load(template.render({'kibana' => {
        'config_options' => {
            'xpack' => {
              'security' => {
                'enabled' => true
              }
          }
        }
      }}, consumes: links))
      expect(config['xpack']['security']['enabled']).to eq(true)
    end
    it 'multiple elasticsearch hosts' do
      config = YAML.safe_load(template.render({'kibana' => {
        'elasticsearch' => {
          'protocol' => 'https',
          'port' => '443'
        }
      }}, consumes: [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.1'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.3'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.4'),
            Bosh::Template::Test::LinkInstance.new(address: '10.0.8.5')
          ],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ]))
      expect(config['elasticsearch.hosts']).to eq([
        'https://10.0.8.1:443',
        'https://10.0.8.2:443',
        'https://10.0.8.3:443',
        'https://10.0.8.4:443',
        'https://10.0.8.5:443'
      ])
    end
    it 'configures an encryption key' do
      config = YAML.safe_load(template.render({'kibana' => {
          'xpack' => {
            'security' => {
              'encryptionKey' => 'some_encryption_key'
            }
          }
      }}, consumes: links))
      puts config
      expect(config['xpack.security.encryptionKey']).to eq('some_encryption_key')
    end
  end
end
