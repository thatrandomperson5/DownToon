curl -s https://api.github.com/repos/thatrandomperson5/DownToon/releases/latest \
| grep "browser_download_url.*bin" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -qi -

if [ "$USE_WEBTOON" = true ] ; then
  rm downtoon.bin
  mv downtoon-wbt.bin downtoon.bin
else
  rm downtoon-wbt.bin
fi
mkdir ~/downtoon/
mv downtoon.bin ~/downtoon/downtoon
echo "Storing in ~/downtoon/, please add it to PATH."
echo "Please make sure you have OpenSSL and FreeImage installed to make this work properly."

## Needs more work