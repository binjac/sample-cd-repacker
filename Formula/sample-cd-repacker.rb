class SampleCdRepacker < Formula
  desc "CLI to repack old 80s–90s sample CDs into clean modern WAV folders"
  homepage "https://github.com/binjac/sample-cd-repacker"
  url "https://github.com/binjac/sample-cd-repacker/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "__FILL_ME_AFTER_RELEASE__"
  license "MIT"

  depends_on "zsh"
  depends_on "sox"
  depends_on "python@3.12"

  def install
    bin.install "repack_interactive.zsh" => "sample-cd-repacker"
    libexec.install "classify.py"
    (bin/"sample-cd-classify").write <<~EOS
      #!/bin/bash
      exec "#{Formula["python@3.12"].opt_bin}/python3" "#{libexec}/classify.py" "$@"
    EOS
  end

  test do
    system "#{bin}/sample-cd-repacker", "--help"
  end
end


