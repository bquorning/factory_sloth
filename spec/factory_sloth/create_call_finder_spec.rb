describe FactorySloth::CreateCallFinder, '::call' do
  it 'works for create calls on the main object' do
    expect(described_class.call(code: 'create')).to eq [[1, 0]]
  end

  it 'works for create_list' do
    expect(described_class.call(code: 'create_list')).to eq [[1, 0]]
  end

  it 'works for create_pair' do
    expect(described_class.call(code: 'create_pair')).to eq [[1, 0]]
  end

  it 'works for calls on FactoryBot' do
    expect(described_class.call(code: <<~RUBY)).to eq [[1, 11], [2, 11]]
      FactoryBot.create
      FactoryBot.create_list
    RUBY
  end

  it 'finds nested create calls' do
    expect(described_class.call(code: 'create(foo: create(:bar))').sort)
      .to eq [[1, 0], [1, 12]]
  end

  it 'works at arbitrary code nesting depths' do
    expect(described_class.call(code: <<~RUBY)).to eq [[5, 34]]
      describe('foo') do
        RSpec.context('bar') do
          it 'baz' do
            def my_helper
              my_proc = -> { FactoryBot.create(:user) }
            end
          end
        end
      end
    RUBY
  end

  it 'ignores unrelated create calls' do
    expect(described_class.call(code: <<~RUBY)).to eq []
      User.create
      self.create
      create!
      FactoryBot.create_factory
    RUBY
  end

  it 'ignores create calls with a sloth:disable comment in the same line' do
    expect(described_class.call(code: <<~RUBY)).to eq [[1, 0], [3, 0]]
      create(:foo)
      create(:foo) # sloth:disable
      create(:foo)
    RUBY
  end

  it 'ignores create calls after a line-leading sloth:disable comment' do
    expect(described_class.call(code: <<~RUBY)).to eq [[1, 0], [6, 0]]
      create(:foo)
      # sloth:disable
      create(:foo)
      create(:foo)
      # sloth:enable
      create(:foo)
    RUBY
  end
end
