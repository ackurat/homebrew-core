class PreCommit < Formula
  include Language::Python::Virtualenv

  desc "Framework for managing multi-language pre-commit hooks"
  homepage "https://pre-commit.com/"
  url "https://files.pythonhosted.org/packages/aa/46/cc214ef6514270328910083d0119d0a80a6d2c4ec8c6608c0219db0b74cf/pre_commit-3.7.1.tar.gz"
  sha256 "8ca3ad567bc78a4972a3f1a477e94a79d4597e8140a6e0b651c5e33899c3654a"
  license "MIT"
  revision 1
  head "https://github.com/pre-commit/pre-commit.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "425eae73daa86d186a176b5a354ca99186b26e485c7f39d08efe44d939d46629"
    sha256 cellar: :any,                 arm64_ventura:  "114381447b1a707ce86bb9d0ed28d9c967ee30638c726caa988d4b0fd5114ddd"
    sha256 cellar: :any,                 arm64_monterey: "42890ab95c61a5d35a237e3f1eac5e2683dd2af869bd06d987f24f08cd308aa0"
    sha256 cellar: :any,                 sonoma:         "3ab7993fe9d2b8dd1f492f6ae3eb729f232bffa67b1e7bea9e125aeb4f356d86"
    sha256 cellar: :any,                 ventura:        "e796c47c7f05b5ab40a35e784d6f1832cee718ccd146fb3b7335710ac6b5f68a"
    sha256 cellar: :any,                 monterey:       "6584817868fdb8aafde3dcf90f64649674fc38257af7d5f7985c5b2714abbac9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "276332e205059dd279baaadf5170061954dfa8bde4593a876d5fb6bab085f15e"
  end

  depends_on "libyaml"
  depends_on "python@3.12"

  resource "cfgv" do
    url "https://files.pythonhosted.org/packages/11/74/539e56497d9bd1d484fd863dd69cbbfa653cd2aa27abfe35653494d85e94/cfgv-3.4.0.tar.gz"
    sha256 "e52591d4c5f5dead8e0f673fb16db7949d2cfb3f7da4582893288f0ded8fe560"
  end

  resource "distlib" do
    url "https://files.pythonhosted.org/packages/c4/91/e2df406fb4efacdf46871c25cde65d3c6ee5e173b7e5a4547a47bae91920/distlib-0.3.8.tar.gz"
    sha256 "1530ea13e350031b6312d8580ddb6b27a104275a31106523b8f123787f494f64"
  end

  resource "filelock" do
    url "https://files.pythonhosted.org/packages/08/dd/49e06f09b6645156550fb9aee9cc1e59aba7efbc972d665a1bd6ae0435d4/filelock-3.15.4.tar.gz"
    sha256 "2207938cbc1844345cb01a5a95524dae30f0ce089eba5b00378295a17e3e90cb"
  end

  resource "identify" do
    url "https://files.pythonhosted.org/packages/32/f4/8e8f7db397a7ce20fbdeac5f25adaf567fc362472432938d25556008e03a/identify-2.6.0.tar.gz"
    sha256 "cb171c685bdc31bcc4c1734698736a7d5b6c8bf2e0c15117f4d469c8640ae5cf"
  end

  resource "nodeenv" do
    url "https://files.pythonhosted.org/packages/43/16/fc88b08840de0e0a72a2f9d8c6bae36be573e475a6326ae854bcc549fc45/nodeenv-1.9.1.tar.gz"
    sha256 "6ec12890a2dab7946721edbfbcd91f3319c6ccc9aec47be7c7e6b7011ee6645f"
  end

  resource "platformdirs" do
    url "https://files.pythonhosted.org/packages/f5/52/0763d1d976d5c262df53ddda8d8d4719eedf9594d046f117c25a27261a19/platformdirs-4.2.2.tar.gz"
    sha256 "38b7b51f512eed9e84a22788b4bce1de17c0adb134d6becb09836e37d8654cd3"
  end

  resource "pyyaml" do
    url "https://files.pythonhosted.org/packages/cd/e5/af35f7ea75cf72f2cd079c95ee16797de7cd71f29ea7c68ae5ce7be1eda0/PyYAML-6.0.1.tar.gz"
    sha256 "bfdf460b1736c775f2ba9f6a92bca30bc2095067b8a9d77876d1fad6cc3b4a43"
  end

  resource "virtualenv" do
    url "https://files.pythonhosted.org/packages/68/60/db9f95e6ad456f1872486769c55628c7901fb4de5a72c2f7bdd912abf0c1/virtualenv-20.26.3.tar.gz"
    sha256 "4c43a2a236279d9ea36a0d76f98d84bd6ca94ac4e0f4a3b9d46d05e10fea542a"
  end

  def python3
    "python3.12"
  end

  def install
    # Avoid Cellar path reference, which is only good for one version.
    inreplace "pre_commit/commands/install_uninstall.py",
              "f'INSTALL_PYTHON={shlex.quote(sys.executable)}\\n'",
              "f'INSTALL_PYTHON={shlex.quote(\"#{opt_libexec}/bin/#{python3}\")}\\n'"

    virtualenv_install_with_resources
  end

  # Avoid relative paths
  def post_install
    xy = Language::Python.major_minor_version Formula["python@3.12"].opt_bin/python3
    dirs_to_fix = [libexec/"lib/python#{xy}"]
    dirs_to_fix << (libexec/"bin") if OS.linux?
    dirs_to_fix.each do |folder|
      folder.each_child do |f|
        next unless f.symlink?

        realpath = f.realpath
        rm f
        ln_s realpath, f
      end
    end
  end

  test do
    system "git", "init"
    (testpath/".pre-commit-config.yaml").write <<~EOS
      repos:
      -   repo: https://github.com/pre-commit/pre-commit-hooks
          rev: v0.9.1
          hooks:
          -   id: trailing-whitespace
    EOS
    system bin/"pre-commit", "install"
    (testpath/"f").write "hi\n"
    system "git", "add", "f"

    ENV["GIT_AUTHOR_NAME"] = "test user"
    ENV["GIT_AUTHOR_EMAIL"] = "test@example.com"
    ENV["GIT_COMMITTER_NAME"] = "test user"
    ENV["GIT_COMMITTER_EMAIL"] = "test@example.com"
    git_exe = which("git")
    ENV["PATH"] = "/usr/bin:/bin"
    system git_exe, "commit", "-m", "test"
  end
end
