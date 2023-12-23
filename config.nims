--define:ssl
when defined(release):
  --define:danger
  --out:downtoon.bin
  --panics:on
  --passC:"-flto"
  --passC:"-march=native"
else:
  --define:enableWebtoons