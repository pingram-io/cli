# Homebrew formula for Pingram CLI.
# Lives in public repo: pingram-io/cli → Formula/pingram.rb
#
#   brew install pingram-io/cli/pingram

class Pingram < Formula
  desc "Official Pingram CLI"
  homepage "https://pingram.io"
  version "1.0.16"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/pingram-io/cli/releases/download/pingram-cli-v1.0.16/pingram-darwin-arm64.tar.gz"
      sha256 "f09514408bffdc3fa25bd365b08673c9dd572afceedda9851c86afa18f9a64aa"
    end
    on_intel do
      url "https://github.com/pingram-io/cli/releases/download/pingram-cli-v1.0.16/pingram-darwin-x64.tar.gz"
      sha256 "c210b3d94cab2f4a94c13f8c85b5643cd9d28ca875fb17f7695d87ce10b602bc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/pingram-io/cli/releases/download/pingram-cli-v1.0.16/pingram-linux-arm64.tar.gz"
      sha256 "fa64d493eefefe707141dba098ea581db24fb624fb021a6f99291cbf52e029c8"
    end
    on_intel do
      url "https://github.com/pingram-io/cli/releases/download/pingram-cli-v1.0.16/pingram-linux-x64.tar.gz"
      sha256 "fc96c56863a9b35fffcfc97a22c5a2eaa5fec405b87038ad96c5aa89f140327c"
    end
  end

  def install
    bin.install "pingram"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/pingram --version")
  end
end
