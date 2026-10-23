cask "duolapse" do
  version :latest
  sha256 :no_check

  url "https://github.com/domesticatedpigeon/DuoLapse/releases/latest/download/DuoLapse.zip"
  name "DuoLapse"
  desc "Lightweight screen and webcam time-lapse recorder"
  homepage "https://github.com/domesticatedpigeon/DuoLapse"

  auto_updates true
  depends_on macos: ">= :tahoe"

  app "DuoLapse.app"

  zap trash: [
    "~/Library/Application Support/DuoLapse",
    "~/Library/Preferences/com.domesticatedpigeon.DuoLapse.plist",
  ]
end
