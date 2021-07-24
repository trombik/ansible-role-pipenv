require "spec_helper"
require "serverspec"

package = "devel/py-pipenv"
extra_packages = %w[ databases/py-sqlite3 ]
service = "youtube_dl"
user    = "youtube-dl"
group   = "youtube-dl"
ports   = [8080]
default_user = "root"
default_group = "wheel"
app_dir = "/usr/local/youtube-dl-server"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/pipenv.conf"
  db_dir = "/var/db/pipenv"
end

describe group group do
  it { should exist }
end

describe user user do
  it { should exist }
  it { should belong_to_primary_group group }
end

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe file "/usr/local/etc/rc.d/youtube_dl" do
  it { should exist }
  it { should be_file }
  it { should be_mode 755 }
  it { should be_owned_by default_user }
  it { should be_grouped_into default_group }
  its(:content) { should match(/name=youtube_dl/) }
end

describe file app_dir do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
  it { should be_directory }
end

describe command "cd #{app_dir} && pipenv --venv" do
  let(:sudo_options) { "-u #{user}" }
  its(:exit_status) { should eq 0 }
  its(:stderr) { should_not match(/No virtualenv/) }
  its(:stdout) { should match(/virtualenvs\/youtube-dl-server/) }
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
