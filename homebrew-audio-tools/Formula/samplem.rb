class Samplem < Formula
  desc "Audio repacker and classifier for legacy sample collections"
  homepage "https://github.com/binjac/samplem"
  url "https://github.com/binjac/samplem/archive/refs/tags/v0.9.0.tar.gz"
  sha256 "3209c370a075c77fb4716f78f1343fea000e8012fe956a5d977dd5076a9024bf"
  license "MIT"

  depends_on "sox"

  def install
    bin.install "bin/samplem"
    bin.install "repack_interactive.zsh"
    bin.install "classify.py" if File.exist?("classify.py")
  end

  test do
    assert_match "samplem", shell_output("#{bin}/samplem --help")
  end
end


