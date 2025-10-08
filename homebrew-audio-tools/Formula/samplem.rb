class Samplem < Formula
  desc "Audio repacker and classifier for legacy sample collections"
  homepage "https://github.com/binjac/samplem"
  url "https://github.com/binjac/samplem/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "__FILL_ME_AFTER_TAG__"
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


