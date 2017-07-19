require_relative('../lib/yaml_line_numbers.rb')
require 'yaml'
require 'rspec'

describe "LineNumberYamlParser" do

  def test_file
    "#{__dir__}/example.yaml"
  end

  def load_yaml(filename)
    LineNumberYamlParser.new.load(filename)
  end

  def has_metadata(obj)
		if !obj.respond_to?(:metadata)
			return false
    end
    if obj.respond_to?(:each)
      for elem in obj do
        has_metadata(elem)
      end
		end
		return true
  end

  def get_line_numbers(obj, output = {})
    if obj.respond_to?(:each)
      for elem in obj do
        get_line_numbers(elem, output)
      end
    elsif obj.respond_to?(:metadata) && obj.metadata != nil
			output[obj.metadata["line"]] ||= []
      output[obj.metadata["line"]] << obj
    end
		return output
  end

  before(:each) do
    @parsed_yaml = YAML.load_file(test_file)
    @parsed_ln_yaml = load_yaml(test_file)
  end

  after(:each) do
    @parsed_yaml = nil
    @parsed_ln_yaml = nil
  end

  it "loads a yaml file and as well as the base package" do
    expect(@parsed_ln_yaml).to eq(@parsed_yaml)
  end

  it "encodes line numbers as metadata" do
		expect(!has_metadata(@parsed_yaml))
		expect(has_metadata(@parsed_ln_yaml))
  end

  it "accurately records line numbers" do
    outputs = get_line_numbers(@parsed_ln_yaml)
		outputs.each do |line_num, strings|
			strings.each do |string|
				expect(string.include?(line_num.to_s))
			end
		end
  end
end
