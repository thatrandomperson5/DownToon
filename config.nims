--define:ssl
when defined(release):
  --define:danger
  when defined(windows):
    --out:downtoon.exe
  else:
    --out:downtoon.bin
  --panics:on
  --passC:"-flto"
  --passC:"-march=native"
else:
  --define:enableWebtoons