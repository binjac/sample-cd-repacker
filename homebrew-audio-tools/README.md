# binjac/homebrew-audio-tools

Tap for audio utilities.

## Usage

```
brew tap binjac/audio-tools
brew install samplem
samplem --help
```

## Updating `samplem`

1. Tag a new release in the upstream repo:
```
git tag v1.0.0
git push origin v1.0.0
```
2. Compute SHA256:
```
curl -L https://github.com/binjac/samplem/archive/refs/tags/v1.0.0.tar.gz | shasum -a 256
```
3. Update `Formula/samplem.rb` `url` and `sha256` accordingly.
