require 'spec_helper'

describe 'ensure_resource' do
  it { is_expected.not_to eq(nil) }
  it { is_expected.to run.with_params.and_raise_error(ArgumentError, %r{Must specify a type}) }
  it { is_expected.to run.with_params('type').and_raise_error(ArgumentError, %r{Must specify a title}) }
  if Puppet::Util::Package.versioncmp(Puppet.version, '4.6.0') >= 0
    it { is_expected.to run.with_params('type', 'title', {}, 'extras').and_raise_error(ArgumentError) }
  else
    it { is_expected.to run.with_params('type', 'title', {}, 'extras').and_raise_error(Puppet::ParseError) }
  end

  it {
    pending('should not accept numbers as arguments')
    is_expected.to run.with_params(1, 2, 3).and_raise_error(Puppet::ParseError)
  }

  context 'when given an empty catalog' do
    describe 'after running ensure_resource("user", "username1", {})' do
      before(:each) { subject.call(['User', 'username1', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').without_ensure }
    end

    describe 'after running ensure_resource("user", "username1", { gid => undef })' do
      before(:each) { subject.call(['User', 'username1', { 'gid' => :undef }]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').without_ensure }
      it { expect(-> { catalogue }).to contain_user('username1').without_gid }
    end

    describe 'after running ensure_resource("user", "username1", { ensure => present, gid => undef })' do
      before(:each) { subject.call(['User', 'username1', { 'ensure' => 'present', 'gid' => :undef }]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with_ensure('present') }
      it { expect(-> { catalogue }).to contain_user('username1').without_gid }
    end

    describe 'after running ensure_resource("test::deftype", "foo", {})' do
      before(:each) { subject.call(['test::deftype', 'foo', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_test__deftype('foo').without_ensure }
    end
  end

  context 'when given a catalog with UTF8 chars' do
    describe 'after running ensure_resource("user", "??????????????? ????????", {})' do
      before(:each) { subject.call(['User', '??????????????? ????????', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('??????????????? ????????').without_ensure }
    end

    describe 'after running ensure_resource("user", "??????????????? ????????", { gid => undef })' do
      before(:each) { subject.call(['User', '??????????????? ????????', { 'gid' => :undef }]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('??????????????? ????????').without_ensure }
      it { expect(-> { catalogue }).to contain_user('??????????????? ????????').without_gid }
    end

    describe 'after running ensure_resource("user", "??????????????? ????????", { ensure => present, gid => undef })' do
      before(:each) { subject.call(['User', '??????????????? ????????', { 'ensure' => 'present', 'gid' => :undef }]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('??????????????? ????????').with_ensure('present') }
      it { expect(-> { catalogue }).to contain_user('??????????????? ????????').without_gid }
    end
  end

  context 'when given a catalog with "user { username1: ensure => present }"' do
    let(:pre_condition) { 'user { username1: ensure => present }' }

    describe 'after running ensure_resource("user", "username1", {})' do
      before(:each) { subject.call(['User', 'username1', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with_ensure('present') }
    end

    describe 'after running ensure_resource("user", "username2", {})' do
      before(:each) { subject.call(['User', 'username2', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with_ensure('present') }
      it { expect(-> { catalogue }).to contain_user('username2').without_ensure }
    end

    describe 'after running ensure_resource("user", "username1", { gid => undef })' do
      before(:each) { subject.call(['User', 'username1', { 'gid' => :undef }]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with_ensure('present') }
    end

    describe 'after running ensure_resource("user", ["username1", "username2"], {})' do
      before(:each) { subject.call(['User', %w[username1 username2], {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with_ensure('present') }
      it { expect(-> { catalogue }).to contain_user('username2').without_ensure }
    end

    describe 'when providing already set params' do
      let(:params) { { 'ensure' => 'present' } }

      before(:each) { subject.call(['User', %w[username2 username3], params]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_user('username1').with(params) }
      it { expect(-> { catalogue }).to contain_user('username2').with(params) }
    end

    context 'when trying to add params' do
      it {
        is_expected.to run \
          .with_params('User', 'username1', 'ensure' => 'present', 'shell' => true) \
          .and_raise_error(Puppet::Resource::Catalog::DuplicateResourceError, %r{User\[username1\] is already declared})
      }
    end
  end

  context 'when given a catalog with "test::deftype { foo: }"' do
    let(:pre_condition) { 'test::deftype { "foo": }' }

    describe 'after running ensure_resource("test::deftype", "foo", {})' do
      before(:each) { subject.call(['test::deftype', 'foo', {}]) }

      # this lambda is required due to strangeness within rspec-puppet's expectation handling
      it { expect(-> { catalogue }).to contain_test__deftype('foo').without_ensure }
    end
  end
end
